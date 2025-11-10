import { describe, it, expect, vi } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import PiiForm from '../components/PiiForm'

describe('PiiForm', () => {
  it('renders all form fields', () => {
    render(<PiiForm onSubmit={vi.fn()} />)

    // Name fields
    expect(screen.getByLabelText(/first name/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/middle name/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/last name/i)).toBeInTheDocument()

    // SSN field
    expect(screen.getByLabelText(/social security number/i)).toBeInTheDocument()

    // Contact fields
    expect(screen.getByLabelText(/email/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/phone/i)).toBeInTheDocument()

    // Address fields
    expect(screen.getByLabelText(/street address(?!.*line 2)/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/city/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/state/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/zip code/i)).toBeInTheDocument()

    // Submit button
    expect(screen.getByRole('button', { name: /save/i })).toBeInTheDocument()
  })

  it('validates required fields and shows error messages', async () => {
    const user = userEvent.setup()
    const mockSubmit = vi.fn()

    render(<PiiForm onSubmit={mockSubmit} />)

    // Try to submit empty form
    const submitButton = screen.getByRole('button', { name: /save/i })
    await user.click(submitButton)

    // Wait for validation errors
    await waitFor(() => {
      expect(screen.getByText(/first name is required/i)).toBeInTheDocument()
      expect(screen.getByText(/last name is required/i)).toBeInTheDocument()
      expect(screen.getByText(/ssn is required/i)).toBeInTheDocument()
      expect(screen.getByText(/street address is required/i)).toBeInTheDocument()
      expect(screen.getByText(/city is required/i)).toBeInTheDocument()
      expect(screen.getByText(/state is required/i)).toBeInTheDocument()
      expect(screen.getByText(/zip code is required/i)).toBeInTheDocument()
    })

    // Form should not be submitted
    expect(mockSubmit).not.toHaveBeenCalled()
  })

  it('formats SSN input with dashes automatically', async () => {
    const user = userEvent.setup()

    render(<PiiForm onSubmit={vi.fn()} />)

    const ssnInput = screen.getByLabelText(/social security number/i)

    // Type SSN digits
    await user.type(ssnInput, '123456789')

    // Should be formatted as XXX-XX-XXXX
    await waitFor(() => {
      expect(ssnInput.value).toBe('123-45-6789')
    })
  })

  it('validates SSN format and shows specific error messages', async () => {
    const user = userEvent.setup()
    const mockSubmit = vi.fn()

    render(<PiiForm onSubmit={mockSubmit} />)

    const ssnInput = screen.getByLabelText(/social security number/i)
    const submitButton = screen.getByRole('button', { name: /save/i })

    // Test invalid SSN with area 000
    await user.clear(ssnInput)
    await user.type(ssnInput, '000-12-3456')
    await user.click(submitButton)

    await waitFor(() => {
      expect(screen.getByText(/area number cannot be 000/i)).toBeInTheDocument()
    })

    // Test invalid SSN with group 00
    await user.clear(ssnInput)
    await user.type(ssnInput, '123-00-4567')
    await user.click(submitButton)

    await waitFor(() => {
      expect(screen.getByText(/group number cannot be 00/i)).toBeInTheDocument()
    })

    // Test invalid SSN with serial 0000
    await user.clear(ssnInput)
    await user.type(ssnInput, '123-45-0000')
    await user.click(submitButton)

    await waitFor(() => {
      expect(screen.getByText(/serial number cannot be 0000/i)).toBeInTheDocument()
    })

    // Test known invalid SSN
    await user.clear(ssnInput)
    await user.type(ssnInput, '123-45-6789')
    await user.click(submitButton)

    await waitFor(() => {
      expect(screen.getByText(/this ssn is known to be invalid/i)).toBeInTheDocument()
    })

    expect(mockSubmit).not.toHaveBeenCalled()
  })

  it('handles middle name override correctly', async () => {
    const user = userEvent.setup()

    render(<PiiForm onSubmit={vi.fn()} />)

    const middleNameInput = screen.getByLabelText(/middle name/i)
    const noMiddleNameCheckbox = screen.getByLabelText(/no middle name/i)

    // Initially, middle name input should be enabled
    expect(middleNameInput).not.toBeDisabled()

    // Type a middle name
    await user.type(middleNameInput, 'Patrick')
    expect(middleNameInput.value).toBe('Patrick')

    // Check the "No middle name" checkbox
    await user.click(noMiddleNameCheckbox)

    // Middle name should be set to "N/A" and input disabled
    await waitFor(() => {
      expect(middleNameInput.value).toBe('N/A')
      expect(middleNameInput).toBeDisabled()
    })

    // Uncheck the checkbox
    await user.click(noMiddleNameCheckbox)

    // Middle name should be cleared and input enabled
    await waitFor(() => {
      expect(middleNameInput.value).toBe('')
      expect(middleNameInput).not.toBeDisabled()
    })
  })

  it('validates email format', async () => {
    const user = userEvent.setup()
    const mockSubmit = vi.fn()

    render(<PiiForm onSubmit={mockSubmit} />)

    const emailInput = screen.getByLabelText(/email/i)
    const submitButton = screen.getByRole('button', { name: /save/i })

    // Enter invalid email
    await user.type(emailInput, 'invalid-email')
    await user.click(submitButton)

    await waitFor(() => {
      expect(screen.getByText(/invalid email address/i)).toBeInTheDocument()
    })

    expect(mockSubmit).not.toHaveBeenCalled()
  })

  it('validates ZIP code format', async () => {
    const user = userEvent.setup()
    const mockSubmit = vi.fn()

    render(<PiiForm onSubmit={mockSubmit} />)

    const zipInput = screen.getByLabelText(/zip code/i)
    const submitButton = screen.getByRole('button', { name: /save/i })

    // Enter invalid ZIP (too short)
    await user.type(zipInput, '1234')
    await user.click(submitButton)

    await waitFor(() => {
      expect(screen.getByText(/zip code must be in format 12345 or 12345-6789/i)).toBeInTheDocument()
    })

    expect(mockSubmit).not.toHaveBeenCalled()
  })

  it('submits form with valid data', async () => {
    const user = userEvent.setup()
    const mockSubmit = vi.fn()

    render(<PiiForm onSubmit={mockSubmit} />)

    // Fill out all required fields
    await user.type(screen.getByLabelText(/first name/i), 'John')
    await user.type(screen.getByLabelText(/last name/i), 'Doe')
    await user.type(screen.getByLabelText(/social security number/i), '234-56-7890')
    await user.type(screen.getByLabelText(/street address(?!.*line 2)/i), '123 Main St')
    await user.type(screen.getByLabelText(/city/i), 'Springfield')
    await user.selectOptions(screen.getByLabelText(/state/i), 'IL')
    await user.type(screen.getByLabelText(/zip code/i), '62701')

    // Submit form
    await user.click(screen.getByRole('button', { name: /save/i }))

    // Wait for submission
    await waitFor(() => {
      expect(mockSubmit).toHaveBeenCalledTimes(1)
    })

    // Check submitted data
    const submittedData = mockSubmit.mock.calls[0][0]
    expect(submittedData.first_name).toBe('John')
    expect(submittedData.last_name).toBe('Doe')
    expect(submittedData.ssn).toBe('234-56-7890')
    expect(submittedData.street_address_1).toBe('123 Main St')
    expect(submittedData.city).toBe('Springfield')
    expect(submittedData.state).toBe('IL')
    expect(submittedData.zip_code).toBe('62701')
  })
})
