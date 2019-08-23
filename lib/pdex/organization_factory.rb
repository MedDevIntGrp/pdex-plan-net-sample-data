require 'fhir_models'
require_relative 'address'
require_relative 'telecom'
require_relative 'utils/states'
require_relative 'utils/nucc_codes'

module PDEX
  class OrganizationFactory
    include Address
    include Telecom

    attr_reader :source_data, :resource_type, :profile, :payer

    def initialize(nppes_organization, payer: false)
      @source_data = nppes_organization
      @resource_type = 'organization'
      @profile = ORGANIZATION_PROFILE_URL
      @payer = payer
    end

    def build
      FHIR::Organization.new(build_params)
    end

    private

    def build_params
      params = {
        id: id,
        meta: meta,
        identifier: identifier,
        active: true,
        type: type,
        name: name,
        telecom: telecom,
        address: address,
      }

      return params if payer

      params.merge(contact: contact)
    end

    def id
      "plannet-#{resource_type}-#{source_data.npi}"
    end

    def meta
      {
        profile: [profile]
      }
    end

    def identifier
      {
        use: 'official',
        type: {
          coding: [
            {
              system: 'http://terminology.hl7.org/CodeSystem/v2-0203',
              code: 'NPI',
              display: 'Provider number',
              userSelected: true
            }
          ],
          text: 'NPI'
        },
        system: 'http://hl7.org/fhir/sid/us-npi',
        value: source_data.npi,
        assigner: {
          display: 'Centers for Medicare and Medicaid Services'
        }
      }
    end

    def type
      [
        {
          coding: [
            {
              system: 'http://terminology.hl7.org/CodeSystem/organization-type',
              code: 'prov',
              display: 'Healthcare Provider'
            }
          ],
          text: 'Healthcare Provider'
        }
      ]
    end

    def name
      source_data.name
    end

    def contact
      {
        purpose: {
          coding: [
            {
              system: 'http://terminology.hl7.org/CodeSystem/contactentity-type',
              code: 'ADMIN',
              display: 'Administrative'
            }
          ]
        },
        name: {
          use: 'official',
          text: "#{source_data.contact_first_name} #{source_data.contact_last_name}",
          family: source_data.contact_last_name,
          given: [source_data.contact_first_name]
        },
        telecom: [
          telecom.first.merge(
            {
              use: 'work',
              extension: [
                {
                  url: CONTACT_POINT_AVAILABLE_TIME_EXTENSION_URL,
                  extension:
                    ['mon', 'tue', 'wed', 'thu', 'fri']
                    .map { |day| { url: 'daysOfWeek', valueCode: day } }
                    .concat(
                      [
                        { url: 'availableStartTime', valueTime: '07:00:00' },
                        { url: 'availableEndTime', valueTime: '18:00:00' }
                      ]
                    )
                }
              ]
            }
          )
        ],
        address: address
      }
    end
  end
end
