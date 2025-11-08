import { useState } from 'react'
import reactLogo from './assets/react.svg'
import viteLogo from '/vite.svg'
import './App.css'

function App() {
  const [count, setCount] = useState(0)

  return (
    <>
      <div>
        <a href="https://vite.dev" target="_blank">
          <img src={viteLogo} className="logo" alt="Vite logo" />
        </a>
        <a href="https://react.dev" target="_blank">
          <img src={reactLogo} className="logo react" alt="React logo" />
        </a>
      </div>
      <h1>Vite + React</h1>
      <div className="card">
        <button onClick={() => setCount((count) => count + 1)}>
          count is {count}
        </button>
        <p>
          Edit <code>src/App.jsx</code> and save to test HMR
        </p>
        <div className="min-h-screen bg-gray-100 flex items-center justify-center">
          <div className="max-w-2xl mx-auto p-8 bg-white rounded-lg shadow-lg">
            <h1 className="text-4xl font-bold text-gray-800 mb-4">
              PII Management System
            </h1>
            <p className="text-lg text-gray-600 mb-6">
              Secure PII collection and storage system
            </p>
            <div className="space-y-4">
              <div className="p-4 bg-blue-50 border-l-4 border-blue-500 rounded">
                <p className="text-sm font-semibold text-blue-700">Frontend Status</p>
                <p className="text-blue-600">React + Vite + Tailwind CSS v4 ✓</p>
              </div>
              <div className="p-4 bg-green-50 border-l-4 border-green-500 rounded">
                <p className="text-sm font-semibold text-green-700">System Status</p>
                <p className="text-green-600">Service is running</p>
              </div>
            </div>
            <p className="mt-6 text-sm text-gray-500">
              Phase 0: Infrastructure Setup Complete
            </p>
          </div>
        </div>
      </div>
      <p className="read-the-docs">
        Click on the Vite and React logos to learn more
      </p>
    </>
  )
}

export default App
