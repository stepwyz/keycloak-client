module KeycloakClient
  module Resources
    module Groups
      def groups(params = {})
        get('/groups', params)
      end

      def group_count(params = {})
        get('/groups/count', params)
      end

      def subgroups(group_id)
        get("/groups/#{group_id}/children")
      end

      def group_by_path(path)
        components = path.split('/')
        components.delete('')

        all_groups = groups({ search: components.last })

        current_groups = all_groups
        components.each do |component|
          group_match = current_groups.detect { _1[:name] == component }

          return nil if group_match.nil?
          return group_match if group_match[:path] == path

          current_groups = group_match[:subGroups]
        end

        nil
      end

      def group(id)
        get("/groups/#{id}")
      end

      def create_group(group, parent_id: nil)
        if parent_id
          post("/groups/#{parent_id}/children", group)
        else
          post('/groups', group)
        end
      end

      def update_group(id, group)
        put("/groups/#{id}", group)
      end

      def delete_group(id)
        delete("/groups/#{id}")
      end

      def group_members(id)
        get("/groups/#{id}/members")
      end

      def add_group_member(group_id, user_id)
        put("/users/#{user_id}/groups/#{group_id}")
      end

      def remove_group_member(group_id, user_id)
        delete("/users/#{user_id}/groups/#{group_id}")
      end

      def group_management_permissions(group_id)
        get("/groups/#{group_id}/management/permissions")
      end

      def update_group_management_permissions(group_id, permissions)
        put("/groups/#{group_id}/management/permissions", permissions)
      end
    end
  end
end
