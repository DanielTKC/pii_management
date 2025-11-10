import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { AuthProvider } from './contexts/AuthContext'
import PrivateRoute from './components/PrivateRoute'
import Login from './pages/Login'
import Signup from './pages/Signup'
import Dashboard from './pages/Dashboard'
import PiiList from './pages/PiiList'
import NewPiiRecord from './pages/NewPiiRecord'
import EditPiiRecord from './pages/EditPiiRecord'

function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route path="/signup" element={<Signup />} />
          <Route
            path="/"
            element={
              <PrivateRoute>
                <Dashboard />
              </PrivateRoute>
            }
          />
          <Route
            path="/pii"
            element={
              <PrivateRoute>
                <PiiList />
              </PrivateRoute>
            }
          />
          <Route
            path="/pii/new"
            element={
              <PrivateRoute>
                <NewPiiRecord />
              </PrivateRoute>
            }
          />
          <Route
            path="/pii/:id/edit"
            element={
              <PrivateRoute>
                <EditPiiRecord />
              </PrivateRoute>
            }
          />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  )
}

export default App
