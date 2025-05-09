---

# 🐾 Animal Rescue Mobile App

A mobile application designed to simplify and streamline animal rescue operations by connecting rescuers, NGOs, and general users in real-time. The app utilizes Firebase, Google Authentication, location services, and push notifications to provide a responsive and interactive rescue ecosystem.

---

## 📱 App Page Structure

### 1. Splash Screen

* App logo
* Name & tagline
* Loading indicator

### 2. Welcome Screen

* Login with Google
* Register with Google

### 3. Registration Page

* Google Sign-In (no manual input for name, email)
* Collect:

    * Phone number
    * User type: Rescuer / NGO / General User
* Location permission request
* Submit button

### 4. Login Page

* Google Sign-In only

### 5. Home / Dashboard

* List of active rescue requests (card format)
* Floating Action Button (FAB) to create new rescue requests
* Tabbed layout:

    * Pending Requests
    * Rescued Animals Log

### 6. Create Rescue Request

* Upload image (camera/gallery)
* Auto-capture user location
* Input for details/notes
* Submit button

### 7. Rescue Request Details

* Animal image
* Map location
* Request description
* Status: Pending / Being Rescued / Rescued
* Assigned rescuer information
* Actions:

    * "Accept Rescue" (rescuers only)
    * "Mark as Rescued" (assigned rescuer only)

### 8. Notifications

* Real-time updates on:

    * New requests
    * Request status changes

### 9. My Profile

* View/Edit:

    * Phone number
    * User type
    * Location
* Logout (Google Sign Out)

### 10. Settings

* Notification preferences
* Theme: Light/Dark
* Privacy settings
* Delete account option

### 11. Admin Panel (Admin Users Only)

* Manage all users
* Manage rescue requests
* Manage rescued animal logs
* Send announcements to users

---

## 🔗 Navigation

* Bottom Navigation Bar:

    * Home
    * Notifications
    * Profile
    * Settings

---

## ⚙️ Core Features

* 🔐 Google Authentication (via Firebase)
* 📍 Location Services Integration
* 🚨 Push Notifications (Firebase Cloud Messaging)
* 🔄 Real-time Request Updates (Firebase / WebSockets)
* 🗺 Rescuers only see requests within a 2km radius
* 🧭 NGOs can view all requests
* ✏️ General Users can post and track their own requests

---

## 🔮 Future Enhancements

* ⚠️ Report system for fake or incorrect rescue requests
* 🗺 Manual location entry as an alternative to GPS
* 🧹 **Temporary Image Storage System**:

    * Implement a queue-like data structure
    * Store each uploaded image temporarily (e.g., 2 days)
    * Automatically delete oldest images after expiration
    * Goal: Prevent storage overflow and allow free, rotating image hosting

---

## 📦 Technologies Used

* Flutter (Frontend)
* Firebase Auth
* Firebase Firestore / Realtime Database
* Firebase Cloud Messaging
* Firebase Storage
* Google Maps API
* WebSocket / Stream-based real-time updates

---

## 🚀 Getting Started

1. Clone the repository:

   ```
   git clone https://github.com/Niketjr/ARS.git
   ```
2. Install dependencies:

   ```
   flutter pub get
   ```
3. Set up Firebase for your project (see `firebase_setup.md`).
4. Run the app:

   ```
   flutter run
   ```

---

