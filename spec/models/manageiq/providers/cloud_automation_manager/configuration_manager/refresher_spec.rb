describe ManageIQ::Providers::CloudAutomationManager::ConfigurationManager::Refresher do
  it ".ems_type" do
    expect(described_class.ems_type).to eq(:cam_configuration)
  end

  context "#refresh" do
    let(:provider) do
      url = Rails.application.secrets.cam.try(:[], :url) || 'CAM_URL'
      FactoryBot.create(:provider_cam, :url => "https://#{url}").tap do |p|
        userid   = Rails.application.secrets.cam.try(:[], :user) || 'CAM_USER'
        password = Rails.application.secrets.cam.try(:[], :password) || 'CAM_PASSWORD'

        p.update_authentication(:default => {:userid => userid, :password => password})
      end
    end

    let(:ems) { provider.configuration_manager }

    it "will perform a full refresh" do
      2.times do
        VCR.use_cassette(described_class.name.underscore) do
          EmsRefresh.refresh(ems)
        end

        ems.reload

        assert_ems_counts
        assert_specific_configuration_profile
      end
    end

    def assert_ems_counts
      expect(ems.configuration_profiles.count).to eq(169)
    end

    def assert_specific_configuration_profile
      configuration_profile = ems.configuration_profiles.find_by(:manager_ref => "5d2f6030c068e4001c9bfbb7")
      expect(configuration_profile).to have_attributes(
        :type        => "ManageIQ::Providers::CloudAutomationManager::ConfigurationManager::ConfigurationProfile",
        :name        => "LAMP stack deployment on AWS",
        :description => "LAMP - A fully-integrated environment for full stack PHP web development.",
      )
    end
  end
end
