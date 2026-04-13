# ============================================================
# Gazebo Motion Capture — Docker Build
# ============================================================
#
# Build the image:
#   docker build -t gazebo-mocap .
#
# Run with Gazebo GUI (requires X11 forwarding from host):
#   xhost +local:docker && docker-compose up
#
# Run headless (no display, e.g. triangulation only):
#   docker run --rm -it --network host gazebo-mocap \
#     ros2 run thermal_3d_localization triangulation_node
#
# ============================================================

FROM osrf/ros:humble-desktop-full

ENV DEBIAN_FRONTEND=noninteractive
ENV ROS_DOMAIN_ID=0
ENV DISPLAY=:0
ENV GAZEBO_IP=127.0.0.1

# Install system ROS2 and utility packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-humble-ros-gz-sim \
    ros-humble-ros-gz-bridge \
    ros-humble-ros-gz-image \
    ros-humble-tf2-ros \
    ros-humble-tf-transformations \
    ros-humble-message-filters \
    ros-humble-cv-bridge \
    ros-humble-ament-cmake-auto \
    python3-opencv \
    python3-numpy \
    python3-yaml \
    python3-pip \
    python3-transforms3d \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages via pip
RUN pip3 install --no-cache-dir transforms3d

# Copy repository into workspace
COPY . /ros2_ws/src/Gazebo-Motion-Capture/

WORKDIR /ros2_ws

# Build the workspace
RUN /bin/bash -c "source /opt/ros/humble/setup.bash && \
    colcon build --symlink-install"

# Create entrypoint script
RUN printf '#!/bin/bash\nsource /opt/ros/humble/setup.bash\nsource /ros2_ws/install/setup.bash\nexec "$@"\n' \
    > /entrypoint.sh && chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
