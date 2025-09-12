module KeycloakClient
  module Resources
    module Organizations
      def organizations(params = {})
        get('/organizations', params)
      end

      def organization_by_alias(org_alias)
        get('/organizations', { search: org_alias }).detect { |org| org[:alias] == org_alias }
      end

      def organization(organization_id)
        get("/organizations/#{organization_id}")
      end

      def delete_organization(organization_id)
        delete("/organizations/#{organization_id}")
      end

      def update_organization(organization_id, organization)
        put("/organizations/#{organization_id}", organization)
      end

      def create_organization(organization)
        post('/organizations', organization)
      end

      def get_organization_member_count(organization_id)
        get("/organizations/#{organization_id}/members/count")
      end

      # TODO: Add pagination
      def get_organization_members(organization_id)
        get("/organizations/#{organization_id}/members")
      end

      def invite_existing_user(organization_id, user_id)
        post("/organizations/#{organization_id}/members/#{user_id}/invite-existing-user")
      end

      # Note: This uses a form post instead of a typcial JSON body
      def invite_user(organization_id, email)
        form_post("/organizations/#{organization_id}/members/invite-user", { email: })
      end

      def create_organization_membership(organization_id, user_id)
        post("/organizations/#{organization_id}/members", user_id)
      end

      def remove_user(organization_id, user_id)
        delete("/organizations/#{organization_id}/members/#{user_id}")
      end

      def get_organization_member(organization_id, member_id)
        get("/organizations/#{organization_id}/members/#{member_id}")
      end

      def get_organization_memberships(organization_id, user_id)
        get("/organizations/#{organization_id}/members/#{user_id}/memberships")
      end
    end
  end
end
