import { createContext, useContext, useState, useEffect } from 'react'
import apiClient from '../services/api'

const AuthContext = createContext(null)

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    // Check if user is already logged in (token exists)
    const token = apiClient.getAuthToken()
    if (token) {
      // In a real app, you'd validate the token with the backend
      // For now, we'll just set a placeholder user
      setUser({ email: 'user@example.com' })
    }
    setLoading(false)
  }, [])

  const login = async (email, password) => {
    try {
      // Call the login API
      const response = await apiClient.post('/api/v1/login', { email, password })

      // Store the token
      apiClient.setAuthToken(response.token)

      // Set user data
      setUser(response.user)

      return { success: true }
    } catch (error) {
      return { success: false, error: error.message }
    }
  }

  const signup = async (email, password) => {
    try {
      // Call the signup API
      const response = await apiClient.post('/api/v1/signup', {
        email,
        password,
        password_confirmation: password
      })

      // Store the token
      apiClient.setAuthToken(response.token)

      // Set user data
      setUser(response.user)

      return { success: true }
    } catch (error) {
      return { success: false, error: error.message }
    }
  }

  const logout = () => {
    apiClient.clearAuthToken()
    setUser(null)
  }

  const value = {
    user,
    login,
    signup,
    logout,
    isAuthenticated: !!user,
    loading,
  }

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const context = useContext(AuthContext)
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider')
  }
  return context
}
