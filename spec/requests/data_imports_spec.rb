require 'rails_helper'

RSpec.describe "DataImports", type: :request do
  let(:admin) { User.create!(email_address: "admin@test.com", password: "password", role: :admin) }
  let(:plain) { User.create!(email_address: "user@test.com",  password: "password") }

  def login(user)
    post session_path, params: { email_address: user.email_address, password: "password" }
  end

  def json_upload
    Rack::Test::UploadedFile.new(
      StringIO.new('{"023":[]}'),
      "application/json",
      original_filename: "test.json"
    )
  end

  describe "GET /data_imports/new" do
    it "allows admin" do
      login(admin)
      get new_data_import_path
      expect(response).to have_http_status(:ok)
    end

    it "redirects non-admin" do
      login(plain)
      get new_data_import_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /data_imports" do
    before { login(admin) }

    it "creates import and enqueues job" do
      expect(DataImportJob).to receive(:perform_later)
      post data_imports_path, params: {
        data_import: {
          start_date:   "20250901T000000Z",
          end_date:     "20250908T000000Z",
          generate_csv: "0",
          input_json:   json_upload
        }
      }
      expect(response).to redirect_to(data_import_path(DataImport.last))
    end

    it "renders new on invalid params" do
      post data_imports_path, params: {
        data_import: { start_date: "", end_date: "", generate_csv: "0" }
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /data_imports/:id" do
    it "shows the import status" do
      imp = DataImport.create!(
        user: admin, start_date: "20250901T000000Z",
        end_date: "20250908T000000Z", status: :completed
      )
      imp.input_json.attach(io: StringIO.new("{}"), filename: "t.json", content_type: "application/json")
      login(admin)
      get data_import_path(imp)
      expect(response).to have_http_status(:ok)
    end
  end
end
