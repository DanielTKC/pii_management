import { useState, useEffect } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { piiRecordsApi } from '../services/api'
import { maskSSN } from '../utils/ssnFormatter'
import { useAuth } from '../contexts/AuthContext'

export default function PiiList() {
  const [records, setRecords] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const { logout } = useAuth()
  const navigate = useNavigate()

  useEffect(() => {
    loadRecords()
  }, [])

  const loadRecords = async () => {
    try {
      setLoading(true)
      const data = await piiRecordsApi.getAll()
      setRecords(data)
    } catch (err) {
      setError('Failed to load records: ' + err.message)
    } finally {
      setLoading(false)
    }
  }

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this record?')) {
      return
    }

    try {
      await piiRecordsApi.delete(id)
      setRecords(records.filter((r) => r.id !== id))
    } catch (err) {
      setError('Failed to delete record: ' + err.message)
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50">
        <nav className="bg-white shadow-sm">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="flex justify-between h-16">
              <div className="flex items-center">
                <h1 className="text-xl font-bold text-gray-900">PII Management System</h1>
              </div>
            </div>
          </div>
        </nav>
        <div className="flex items-center justify-center min-h-screen">
          <div className="text-lg">Loading...</div>
        </div>
      </div>
    )
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
          <div className="flex justify-between items-center mb-6">
            <h2 className="text-2xl font-bold text-gray-900">PII Records</h2>
            <Link
              to="/pii/new"
              className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700"
            >
              Add New Record
            </Link>
          </div>

          {error && (
            <div className="mb-4 rounded-md bg-red-50 p-4">
              <div className="text-sm text-red-800">{error}</div>
            </div>
          )}

          {records.length === 0 ? (
            <div className="text-center py-12">
              <p className="text-gray-500">No records found.</p>
              <Link
                to="/pii/new"
                className="mt-4 inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700"
              >
                Create Your First Record
              </Link>
            </div>
          ) : (
            <div className="bg-white shadow overflow-hidden sm:rounded-md">
              <ul className="divide-y divide-gray-200">
                {records.map((record) => (
                  <li key={record.id}>
                    <div className="px-4 py-4 sm:px-6 hover:bg-gray-50">
                      <div className="flex items-center justify-between">
                        <div className="flex-1">
                          <h3 className="text-lg font-medium text-gray-900">
                            {record.first_name} {record.middle_name && record.middle_name !== 'N/A' ? record.middle_name + ' ' : ''}
                            {record.last_name}
                          </h3>
                          <div className="mt-2 grid grid-cols-2 gap-4 text-sm text-gray-500">
                            <div>
                              <span className="font-medium">SSN:</span> {maskSSN(record.ssn_last_four)}
                            </div>
                            {record.email && (
                              <div>
                                <span className="font-medium">Email:</span> {record.email}
                              </div>
                            )}
                            {record.phone && (
                              <div>
                                <span className="font-medium">Phone:</span> {record.phone}
                              </div>
                            )}
                            <div>
                              <span className="font-medium">Address:</span>{' '}
                              {record.street_address_1}, {record.city}, {record.state} {record.zip_code}
                            </div>
                          </div>
                        </div>
                        <div className="flex space-x-2">
                          <button
                            onClick={() => navigate(`/pii/${record.id}/edit`)}
                            className="inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm leading-4 font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
                          >
                            Edit
                          </button>
                          <button
                            onClick={() => handleDelete(record.id)}
                            className="inline-flex items-center px-3 py-2 border border-red-300 shadow-sm text-sm leading-4 font-medium rounded-md text-red-700 bg-white hover:bg-red-50"
                          >
                            Delete
                          </button>
                        </div>
                      </div>
                    </div>
                  </li>
                ))}
              </ul>
            </div>
          )}
        </div>
      </main>
    </div>
  )
}
