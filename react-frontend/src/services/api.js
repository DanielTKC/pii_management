const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000'

class ApiClient {
  constructor() {
    this.baseURL = API_BASE_URL
  }

  async request(endpoint, options = {}) {
    const url = `${this.baseURL}${endpoint}`
    const config = {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        ...options.headers,
      },
    }

    // Add auth token if available
    const token = localStorage.getItem('authToken')
    if (token) {
      config.headers['Authorization'] = `Bearer ${token}`
    }

    try {
      const response = await fetch(url, config)

      // Handle non-200 responses
      if (!response.ok) {
        const error = await response.json().catch(() => ({ error: 'Request failed' }))
        throw new Error(error.error || `HTTP ${response.status}`)
      }

      // Parse JSON response
      return await response.json()
    } catch (error) {
      console.error('API Error:', error)
      throw error
    }
  }

  // GET request
  async get(endpoint) {
    return this.request(endpoint, { method: 'GET' })
  }

  // POST request
  async post(endpoint, data) {
    return this.request(endpoint, {
      method: 'POST',
      body: JSON.stringify(data),
    })
  }

  // PUT request
  async put(endpoint, data) {
    return this.request(endpoint, {
      method: 'PUT',
      body: JSON.stringify(data),
    })
  }

  // DELETE request
  async delete(endpoint) {
    return this.request(endpoint, { method: 'DELETE' })
  }

  // Authentication methods
  setAuthToken(token) {
    localStorage.setItem('authToken', token)
  }

  clearAuthToken() {
    localStorage.removeItem('authToken')
  }

  getAuthToken() {
    return localStorage.getItem('authToken')
  }
}

// Create singleton instance
const apiClient = new ApiClient()

// PII Records API
export const piiRecordsApi = {
  getAll: () => apiClient.get('/api/v1/pii_records'),
  getById: (id) => apiClient.get(`/api/v1/pii_records/${id}`),
  create: (data) => apiClient.post('/api/v1/pii_records', { pii_record: data }),
  update: (id, data) => apiClient.put(`/api/v1/pii_records/${id}`, { pii_record: data }),
  delete: (id) => apiClient.delete(`/api/v1/pii_records/${id}`),
}

// Authentication API (placeholder - implement when backend is ready)
export const authApi = {
  login: (credentials) => apiClient.post('/api/v1/auth/login', credentials),
  signup: (userData) => apiClient.post('/api/v1/auth/signup', userData),
  logout: () => {
    apiClient.clearAuthToken()
    return Promise.resolve()
  },
}

export default apiClient
