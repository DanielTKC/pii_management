import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { piiRecordsApi } from '../services/api'
import PiiForm from '../components/PiiForm'
import { useAuth } from '../contexts/AuthContext'

export default function NewPiiRecord() {
  const [error, setError] = useState('')
  const navigate = useNavigate()
  const { logout } = useAuth()

  const handleSubmit = async (data) => {
    try {
      await piiRecordsApi.create(data)
      navigate('/pii')
    } catch (err) {
      setError('Failed to create record: ' + err.message)
    }
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16">
            <div className="flex items-center space-x-8">
              <Link to="/" className="text-xl font-bold text-gray-900">
                PII Management System
              </Link>
              <Link to="/pii" className="text-sm text-blue-600 font-medium">
                Records
              </Link>
            </div>
            <div className="flex items-center space-x-4">
              <button
                onClick={logout}
                className="text-sm text-gray-700 hover:text-gray-900"
              >
                Logout
              </button>
            </div>
          </div>
        </div>
      </nav>

      <main className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <div className="px-4 py-6 sm:px-0">
          <div className="mb-6">
            <Link to="/pii" className="text-sm text-blue-600 hover:text-blue-800">
              ← Back to Records
            </Link>
          </div>

          <h2 className="text-2xl font-bold text-gray-900 mb-6">New PII Record</h2>

          {error && (
            <div className="mb-4 rounded-md bg-red-50 p-4">
              <div className="text-sm text-red-800">{error}</div>
            </div>
          )}

          <div className="bg-white shadow sm:rounded-lg p-6">
            <PiiForm onSubmit={handleSubmit} submitLabel="Create Record" />
          </div>
        </div>
      </main>
    </div>
  )
}
