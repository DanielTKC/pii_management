import { useForm } from 'react-hook-form'
import { formatSSN, validateSSN } from '../utils/ssnFormatter'

const US_STATES = [
  'AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA',
  'HI', 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD',
  'MA', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ',
  'NM', 'NY', 'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC',
  'SD', 'TN', 'TX', 'UT', 'VT', 'VA', 'WA', 'WV', 'WI', 'WY'
]

export default function PiiForm({ onSubmit, initialData = {}, submitLabel = 'Save' }) {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
    watch,
    setValue,
  } = useForm({
    defaultValues: {
      first_name: initialData.first_name || '',
      middle_name: initialData.middle_name || '',
      last_name: initialData.last_name || '',
      ssn: initialData.ssn || '',
      date_of_birth: initialData.date_of_birth || '',
      email: initialData.email || '',
      phone: initialData.phone || '',
      street_address_1: initialData.street_address_1 || '',
      street_address_2: initialData.street_address_2 || '',
      city: initialData.city || '',
      state: initialData.state || '',
      zip_code: initialData.zip_code || '',
      middle_name_override: initialData.middle_name_override || false,
    },
  })

  const middleNameOverride = watch('middle_name_override')

  // Handle SSN formatting
  const handleSSNChange = (e) => {
    const formatted = formatSSN(e.target.value)
    setValue('ssn', formatted)
  }

  // Handle middle name override
  const handleMiddleNameOverride = (e) => {
    if (e.target.checked) {
      setValue('middle_name', 'N/A')
    } else {
      setValue('middle_name', '')
    }
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-6 max-w-2xl">
      {/* Name Fields */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div>
          <label htmlFor="first_name" className="block text-sm font-medium text-gray-700">
            First Name *
          </label>
          <input
            type="text"
            id="first_name"
            {...register('first_name', {
              required: 'First name is required',
              maxLength: { value: 50, message: 'First name must be 50 characters or less' },
            })}
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 px-3 py-2 border"
          />
          {errors.first_name && (
            <p className="mt-1 text-sm text-red-600">{errors.first_name.message}</p>
          )}
        </div>

        <div>
          <label htmlFor="middle_name" className="block text-sm font-medium text-gray-700">
            Middle Name
          </label>
          <input
            type="text"
            id="middle_name"
            {...register('middle_name', {
              maxLength: { value: 50, message: 'Middle name must be 50 characters or less' },
            })}
            disabled={middleNameOverride}
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 px-3 py-2 border disabled:bg-gray-100"
          />
          <div className="mt-1">
            <label className="inline-flex items-center text-sm">
              <input
                type="checkbox"
                {...register('middle_name_override')}
                onChange={handleMiddleNameOverride}
                className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
              />
              <span className="ml-2">No middle name</span>
            </label>
          </div>
          {errors.middle_name && (
            <p className="mt-1 text-sm text-red-600">{errors.middle_name.message}</p>
          )}
        </div>

        <div>
          <label htmlFor="last_name" className="block text-sm font-medium text-gray-700">
            Last Name *
          </label>
          <input
            type="text"
            id="last_name"
            {...register('last_name', {
              required: 'Last name is required',
              maxLength: { value: 50, message: 'Last name must be 50 characters or less' },
            })}
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 px-3 py-2 border"
          />
          {errors.last_name && (
            <p className="mt-1 text-sm text-red-600">{errors.last_name.message}</p>
          )}
        </div>
      </div>

      {/* SSN Field */}
      <div>
        <label htmlFor="ssn" className="block text-sm font-medium text-gray-700">
          Social Security Number *
        </label>
        <input
          type="text"
          id="ssn"
          {...register('ssn', {
            required: 'SSN is required',
            validate: validateSSN,
          })}
          onChange={handleSSNChange}
          placeholder="XXX-XX-XXXX"
          maxLength={11}
          className="mt-1 block w-full max-w-xs rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 px-3 py-2 border"
        />
        {errors.ssn && (
          <p className="mt-1 text-sm text-red-600">{errors.ssn.message}</p>
        )}
      </div>

      {/* Contact Fields */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label htmlFor="email" className="block text-sm font-medium text-gray-700">
            Email
          </label>
          <input
            type="email"
            id="email"
            {...register('email', {
              pattern: {
                value: /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i,
                message: 'Invalid email address',
              },
            })}
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 px-3 py-2 border"
          />
          {errors.email && (
            <p className="mt-1 text-sm text-red-600">{errors.email.message}</p>
          )}
        </div>

        <div>
          <label htmlFor="phone" className="block text-sm font-medium text-gray-700">
            Phone
          </label>
          <input
            type="tel"
            id="phone"
            {...register('phone')}
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 px-3 py-2 border"
          />
        </div>
      </div>

      {/* Address Fields */}
      <div className="space-y-4">
        <div>
          <label htmlFor="street_address_1" className="block text-sm font-medium text-gray-700">
            Street Address *
          </label>
          <input
            type="text"
            id="street_address_1"
            {...register('street_address_1', { required: 'Street address is required' })}
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 px-3 py-2 border"
          />
          {errors.street_address_1 && (
            <p className="mt-1 text-sm text-red-600">{errors.street_address_1.message}</p>
          )}
        </div>

        <div>
          <label htmlFor="street_address_2" className="block text-sm font-medium text-gray-700">
            Street Address Line 2
          </label>
          <input
            type="text"
            id="street_address_2"
            {...register('street_address_2')}
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 px-3 py-2 border"
          />
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="md:col-span-1">
            <label htmlFor="city" className="block text-sm font-medium text-gray-700">
              City *
            </label>
            <input
              type="text"
              id="city"
              {...register('city', { required: 'City is required' })}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 px-3 py-2 border"
            />
            {errors.city && (
              <p className="mt-1 text-sm text-red-600">{errors.city.message}</p>
            )}
          </div>

          <div>
            <label htmlFor="state" className="block text-sm font-medium text-gray-700">
              State *
            </label>
            <select
              id="state"
              {...register('state', { required: 'State is required' })}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 px-3 py-2 border"
            >
              <option value="">Select State</option>
              {US_STATES.map((state) => (
                <option key={state} value={state}>
                  {state}
                </option>
              ))}
            </select>
            {errors.state && (
              <p className="mt-1 text-sm text-red-600">{errors.state.message}</p>
            )}
          </div>

          <div>
            <label htmlFor="zip_code" className="block text-sm font-medium text-gray-700">
              ZIP Code *
            </label>
            <input
              type="text"
              id="zip_code"
              {...register('zip_code', {
                required: 'ZIP code is required',
                pattern: {
                  value: /^\d{5}(-\d{4})?$/,
                  message: 'ZIP code must be in format 12345 or 12345-6789',
                },
              })}
              placeholder="12345"
              maxLength={10}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 px-3 py-2 border"
            />
            {errors.zip_code && (
              <p className="mt-1 text-sm text-red-600">{errors.zip_code.message}</p>
            )}
          </div>
        </div>
      </div>

      {/* Submit Button */}
      <div className="flex justify-end">
        <button
          type="submit"
          disabled={isSubmitting}
          className="px-6 py-2 bg-blue-600 text-white font-medium rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 disabled:bg-gray-400 disabled:cursor-not-allowed"
        >
          {isSubmitting ? 'Saving...' : submitLabel}
        </button>
      </div>
    </form>
  )
}
