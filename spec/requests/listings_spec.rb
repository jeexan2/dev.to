require "rails_helper"

RSpec.describe "/listings", type: :request do
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }
  let(:cl_category) { create(:classified_listing_category) }

  describe "GETS /listings" do
    it "has page content" do
      get "/listings"
      expect(response.body).to include("classified-filters")
    end

    it "has page content for category page" do
      get "/listings/saas"
      expect(response.body).to include("classified-filters")
    end
  end

  describe "GETS /listings/new" do
    it "has page content" do
      get "/listings"
      expect(response.body).to include("classified-filters")
    end
  end

  describe "POST /listings" do
    before do
      create_list(:credit, 20, user_id: user.id)
      sign_in user
    end

    let(:params) do
      {
        classified_listing: {
          title: "Hey",
          classified_listing_category_id: cl_category.id,
          body_markdown: "hey hey my my"
        }
      }
    end
    let(:params_with_tag_list) do
      {
        classified_listing: {
          title: "Hey",
          classified_listing_category_id: cl_category.id,
          body_markdown: "hey hey my my",
          tag_list: "ruby, rails, go"
        }
      }
    end

    it "creates proper listing if credits are available" do
      post "/listings", params: params
      listing = ClassifiedListing.last
      expect(listing.processed_html).to include("hey my")
    end

    it "spends credits" do
      expect do
        post "/listings", params: params
      end.to change { Credit.where(spent: true).size }
    end

    it "adds tags" do
      expect do
        post "/listings", params: params_with_tag_list
      end.to change(ClassifiedListing, :count).by(1)
      expect(ClassifiedListing.last.cached_tag_list).to include("rails")
    end

    it "creates the listing under the user" do
      post "/listings", params: params_with_tag_list
      listing = ClassifiedListing.last
      expect(listing.user_id).to eq user.id
    end

    it "creates the listing for the user if no organization_id is selected" do
      create(:organization_membership, user_id: user.id, organization_id: organization.id)
      post "/listings", params: params_with_tag_list
      listing = ClassifiedListing.last
      expect(listing.organization_id).to eq nil
      expect(listing.user_id).to eq user.id
    end

    it "creates the listing for the organization" do
      create(:organization_membership, user_id: user.id, organization_id: organization.id)
      params[:classified_listing][:organization_id] = organization_id
      
      post "/listings", params: params_with_tag_list
      
      listing = ClassifiedListing.last
      expect(listing.organization_id).to eq(organization.id)
    end

    it "does not create an org listing if a different org member doesn't belong to the org" do
      another_org = create(:organization)
      create(:organization_membership, user_id: user.id, organization_id: another_org.id)
      params[:classified_listing][:organization_id] = organization_id

      post "/listings", params: params_with_tag_list
      
      listing = ClassifiedListing.last
      expect(listing.organization_id).to eq(organization.id)
    end
  end
end
