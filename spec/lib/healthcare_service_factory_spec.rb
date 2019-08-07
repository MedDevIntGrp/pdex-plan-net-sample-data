# require_relative '../../lib/pdex'
require_relative '../../lib/pdex/healthcare_service_factory'
# require_relative '../../lib/pdex/utils/nucc_codes'

RSpec.describe PDEX::HealthcareServiceFactory do
  let(:organization) do
    OpenStruct.new(
      {
        npi: '1740283779',
        name: 'NAME',
        phone_numbers: [
          '1234567890',
          '2345678901'
        ],
        fax_numbers: [
          '0987654321'
        ],
        # address: address,
        contact_first_name: 'FNAME',
        contact_last_name: 'LNAME'
      }
    )
  end

  # let(:address) do
  #   OpenStruct.new(
  #     {
  #       lines: ['1000 ASYLUM AVE', 'STE 4309'],
  #       city: 'HARTFORD',
  #       state: 'CT',
  #       zip: '061051770'
  #     }
  #   )
  # end

  let(:factory) { described_class.new(organization, type) }
  let(:resource) { factory.build }
  let(:type) { 'administration' }
  let(:telecom) { resource.telecom.first }
  let(:identifier) { resource.identifier.first }
  # let(:contact) { resource.contact.first }

  describe '.initialize' do
    it 'creates an HealthcareServiceFactory instance' do
      expect(factory).to be_a(described_class)
    end
  end

  describe '#build' do
    it 'returns a HealthcareService' do
      expect(resource).to be_a(FHIR::HealthcareService)
    end

    it 'includes an id' do
      expect(resource.id).to be_present
    end

    it 'includes a meta field' do
      expect(resource.meta.profile.first).to eq(PDEX::HEALTHCARE_SERVICE_PROFILE_URL)
    end

    it 'includes an identifier' do
      expect(identifier.type.coding.first.code).to eq('PRN')
      expect(identifier.value).to eq("#{organization.npi}-#{type}")
    end

    it 'includes providedBy' do
      expect(resource.providedBy).to be_present
    end

    it 'includes a type' do
      expect(resource.type).to be_present
    end

    it 'includes a location reference' do
      expect(resource.location).to be_present
    end

    it 'includes a name' do
      expect(resource.name).to eq(organization.name)
    end

    it 'includes a phone number' do
      expect(telecom.system).to eq('phone')
      expect(telecom.value).to eq('1234567890')
    end

    it 'includes a comment' do
      expect(resource.comment).to be_present
      expect(resource.comment).to eq 'Specialties include: Registered Nurse/Administrator, Specialist/Technologist, Health Information/Registered Record Administrator, Pathology/Clinical Laboratory Director, Non-physician'
    end

    it 'includes specalties' do
      expect(resource.specialty).to be_present
      expect(resource.specialty.length).to eq(3)
    end
  end
end
