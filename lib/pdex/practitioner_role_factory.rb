require 'fhir_models'
require 'securerandom'
require_relative 'fhir_elements'
require_relative 'telecom'
require_relative 'utils/formatting'

module PDEX
  class PractitionerRoleFactory
    include Formatting
    include FHIRElements
    include Telecom

    attr_reader :source_data, :organization_data, :network_data

    def initialize(nppes_data, organization:, networks:)
      @source_data = nppes_data
      @organization_data = organization
      @network_data = networks
    end

    def build
      FHIR::PractitionerRole.new(
        {
          id: id,
          meta: meta,
          identifier: identifier,
          active: true,
          extension: extensions,
          practitioner: practitioner,
          organization: organization,
          code: code,
          specialty: specialty,
          location: location,
          telecom: telecom,
          availableTime: available_time
        }
      )
    end

    private

    def id
      "plannet-practitionerrole-#{source_data.npi}"
    end

    def meta
      {
        profile: [PRACTITIONER_ROLE_PROFILE_URL],
      }
    end

    def identifier
      {
        use: 'secondary',
        type: {
          coding: [
            {
              system: 'http://terminology.hl7.org/CodeSystem/v2-0203',
              code: 'PRN',
              display: 'Provider Number'
            }
          ],
          text: 'Hospital ID'
        },
        system: "https://#{format_for_url(organization_data.name)}.com",
        value: SecureRandom.hex(7)
      }
    end

    def extensions
      network_data.map do |network|
        {
          url: PARTICIPATING_NETWORK_EXTENSION_URL,
          valueReference: {
            reference: "Organization/plannet-network-#{network.npi}",
            display: network.name
          }
        }
      end
    end

    def practitioner
      {
        reference: "Practitioner/plannet-practitioner-#{source_data.npi}",
        display: "#{source_data.name.first} #{source_data.name.last}"
      }
    end

    def organization
      {
        reference: "Organization/plannet-organization-#{organization_data.npi}",
        display: organization_data.name
      }
    end

    def code
      [nucc_codeable_concept(source_data.qualifications.first)]
    end

    def specialty
      source_data.qualifications
        .map { |qualification| nucc_codeable_concept(qualification) }
        .first
    end

    def location
      [
        {
          reference: "Location/plannet-location-#{organization_data.npi}",
          display: organization_data.name
        }
      ]
    end

    def available_time
      [
        {
          daysOfWeek: ['mon', 'tue', 'wed', 'thu'],
          availableStartTime: '09:00:00',
          availableEndTime: '12:00:00'
        }
      ]
    end
  end
end
