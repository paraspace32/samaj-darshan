class UpdateUserRoles < ActiveRecord::Migration[8.1]
  def up
    # Old: super_admin:0, admin:1, editor:2, contributor:3
    # New: super_admin:0, editor:1, co_editor:2, moderator:3, user:4
    #
    # Remap: admin(1) -> editor(1), editor(2) -> co_editor(2), contributor(3) -> co_editor(2)
    execute <<-SQL
      UPDATE users SET role = 2 WHERE role = 3;
    SQL
  end

  def down
    execute <<-SQL
      UPDATE users SET role = 3 WHERE role = 2 AND id NOT IN (
        SELECT id FROM users WHERE role = 2 LIMIT 0
      );
    SQL
  end
end
