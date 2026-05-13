# frozen_string_literal: true

RSpec.describe 'live: Groups resource', :integration do
  let(:admin) { AdminClientBuilder.build }

  it 'creates, reads, updates, deletes a group and finds it by path' do
    name = "group-#{SecureRandom.hex(4)}"
    admin.create_group({ name: name })

    found = admin.group_by_path("/#{name}")
    expect(found).not_to be_nil
    expect(found[:name]).to eq(name)

    admin.update_group(found[:id], found.merge(attributes: { foo: ['bar'] }))
    expect(admin.group(found[:id])[:attributes][:foo]).to eq(['bar'])

    expect { admin.delete_group(found[:id]) }.to_not raise_error
  end

  it 'manages group membership for a user' do
    name = "members-#{SecureRandom.hex(4)}"
    admin.create_group({ name: name })
    group = admin.group_by_path("/#{name}")

    username = "user-#{SecureRandom.hex(4)}"
    admin.create_user(username: username, enabled: true)
    user = admin.users(username: username, exact: true).first

    admin.add_group_member(group[:id], user[:id])
    expect(admin.group_members(group[:id]).map { |u| u[:id] }).to include(user[:id])

    admin.remove_group_member(group[:id], user[:id])
    expect(admin.group_members(group[:id])).to be_empty
  ensure
    admin.delete_user(user[:id]) if user
    admin.delete_group(group[:id]) if group
  end

  it 'creates nested subgroups' do
    parent_name = "parent-#{SecureRandom.hex(4)}"
    child_name  = "child-#{SecureRandom.hex(4)}"
    admin.create_group({ name: parent_name })
    parent = admin.group_by_path("/#{parent_name}")

    admin.create_group({ name: child_name }, parent_id: parent[:id])
    expect(admin.subgroups(parent[:id]).map { |g| g[:name] }).to include(child_name)
  ensure
    admin.delete_group(parent[:id]) if parent
  end
end
