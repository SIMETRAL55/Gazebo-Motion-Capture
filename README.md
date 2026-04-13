# Gazebo Thermal Camera Triangulation

A ROS2-based motion capture system using thermal cameras for 3D target localization through triangulation in Gazebo simulation.

## Overview

Eight thermal cameras are arranged around a simulated room. Each camera runs a detector node that publishes 2D pixel coordinates of the thermal target. A triangulation node fuses all detections into a real-time 3D position estimate published on `/thermal_target/position`.

Two ROS2 packages:
- **mocap_ir_ros2** — Gazebo simulation world with thermal cameras (C++/ament_cmake)
- **thermal_3d_localization** — detector nodes + triangulation + RViz visualization (Python/ament_python)

## Features

- Multi-camera triangulation using 8 thermal cameras
- Ground-plane intersection and linear least-squares triangulation methods
- Outlier filtering via reprojection error
- Static TF broadcast for all camera frames
- RViz markers for camera FOV, detection rays, and target position
- JSON-based camera calibration

## Camera Layout

- **4 corner cameras** — room corners, 5 m height, looking down
- **4 wall cameras** — mid-walls, 2.5 m height, side coverage

## Coordinate System

- World frame: `map` (configurable)
- Camera frames: `cam1` … `cam8`
- Target frame: `thermal_target`

---

## Running with Docker (recommended)

Docker is the easiest way to run on any OS. No ROS2 install required.

### Prerequisites

Install Docker:
```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker
sudo apt-get install -y docker-compose-plugin
```

### 1. Build the image

```bash
cd Gazebo-Motion-Capture
docker build -t gazebo-mocap .
```

### 2. Allow GUI (for Gazebo window)

```bash
xhost +local:docker
```

### 3. Start the container

```bash
docker compose up
```

### 4. Launch Gazebo (Terminal 2)

```bash
docker exec -it gazebo-motion-capture-gazebo_mocap-1 bash
source /opt/ros/humble/setup.bash && source /ros2_ws/install/setup.bash
ros2 launch mocap_ir_ros2 mocap_ir.launch.py
```

### 5. Launch detection + triangulation (Terminal 3)

```bash
docker exec -it gazebo-motion-capture-gazebo_mocap-1 bash
source /opt/ros/humble/setup.bash && source /ros2_ws/install/setup.bash
ros2 launch thermal_3d_localization all.launch.py
```

### 6. Visualize in RViz (Terminal 4)

```bash
docker exec -it gazebo-motion-capture-gazebo_mocap-1 bash
source /opt/ros/humble/setup.bash && source /ros2_ws/install/setup.bash
ros2 run rviz2 rviz2
```

Add these topics in RViz:
- `/triangulation_markers` (MarkerArray) — camera FOV and detection rays
- `/thermal_target/position` (PointStamped) — 3D target position

### Run headless (no display)

```bash
docker run --rm -it --network host gazebo-mocap \
  ros2 run thermal_3d_localization triangulation_node
```

---

## Native Install (Ubuntu 22.04 only)

> ROS2 Humble requires Ubuntu 22.04 exactly. It will not install on 24.04 or later.

### Dependencies

```bash
sudo apt-get install -y \
  ros-humble-desktop-full \
  ros-humble-ros-gz-sim ros-humble-ros-gz-bridge ros-humble-ros-gz-image \
  ros-humble-tf2-ros ros-humble-tf-transformations ros-humble-message-filters \
  ros-humble-cv-bridge ros-humble-ament-cmake-auto \
  python3-opencv python3-numpy python3-pip python3-transforms3d
pip3 install transforms3d
```

### Build

```bash
git clone https://github.com/SIMETRAL55/Gazebo-Motion-Capture.git
mkdir -p ~/ros2_ws/src
cp -r Gazebo-Motion-Capture ~/ros2_ws/src/
cd ~/ros2_ws
source /opt/ros/humble/setup.bash
colcon build --symlink-install
source install/setup.bash
```

### Run

**Terminal 1 — Gazebo:**
```bash
source /opt/ros/humble/setup.bash && source install/setup.bash
ros2 launch mocap_ir_ros2 mocap_ir.launch.py
```

**Terminal 2 — Detection + triangulation:**
```bash
source /opt/ros/humble/setup.bash && source install/setup.bash
ros2 launch thermal_3d_localization all.launch.py
```

---

## Algorithm

1. **Detection** — each of 8 `thermal_detector_node` instances processes its camera feed and publishes the target's 2D pixel location
2. **Triangulation** — `triangulation_node` collects rays from all cameras, runs ground-plane intersection for an initial estimate, then refines with linear least-squares
3. **Outlier removal** — detections with high reprojection error are dropped before the final estimate
4. **Output** — 3D position published to `/thermal_target/position` (PointStamped); TF broadcast as `map → thermal_target`
