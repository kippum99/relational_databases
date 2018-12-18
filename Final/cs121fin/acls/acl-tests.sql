CALL clear_perms();

-- Grant Alice some execute permissions.  Delete permission is
-- implicitly revoked.
CALL add_perm('/a', 'alice', 'execute', TRUE);
CALL add_perm('/a/b', 'alice', 'execute', FALSE);
CALL add_perm('/a/b/c', 'alice', 'execute', TRUE);

-- Additional permissions to test that path names are used correctly.
CALL add_perm('/ab', 'alice', 'execute', TRUE);
CALL add_perm('/ab/c', 'alice', 'execute', FALSE);

-- Grant Bob some execute permissions.  Delete permission is
-- explicitly revoked.
CALL add_perm('/a/b', 'bob', 'execute', TRUE);
CALL add_perm('/a/b/c/d', 'bob', 'execute', FALSE);
CALL add_perm('/a', 'bob', 'delete', FALSE);

SELECT TRUE AS expected, has_perm('/a', 'alice', 'execute');
SELECT FALSE AS expected, has_perm('/a', 'alice', 'delete');
SELECT FALSE AS expected, has_perm('/a/b', 'alice', 'execute');
SELECT TRUE AS expected, has_perm('/a/b/c', 'alice', 'execute');
SELECT TRUE AS expected, has_perm('/a/b/c/d', 'alice', 'execute');
SELECT FALSE AS expected, has_perm('/a/b/c/d', 'alice', 'delete');

SELECT TRUE AS expected, has_perm('/ab', 'alice', 'execute');
SELECT FALSE AS expected, has_perm('/ab/c', 'alice', 'execute');
SELECT TRUE AS expected, has_perm('/ab/cd', 'alice', 'execute');
SELECT FALSE AS expected, has_perm('/ab/c/d', 'alice', 'execute');

SELECT FALSE AS expected, has_perm('/a', 'bob', 'execute');
SELECT FALSE AS expected, has_perm('/a', 'bob', 'delete');
SELECT TRUE AS expected, has_perm('/a/b', 'bob', 'execute');
SELECT TRUE AS expected, has_perm('/a/b/c', 'bob', 'execute');
SELECT FALSE AS expected, has_perm('/a/b/c/d', 'bob', 'execute');
SELECT FALSE AS expected, has_perm('/a/b/c', 'bob', 'delete');
SELECT FALSE AS expected, has_perm('/a/b/c/d', 'bob', 'delete');

-- Test that permission deletion works.
CALL del_perm('/ab', 'alice', 'execute');

-- These permission answers should change based on the deletion.
SELECT FALSE AS expected, has_perm('/ab', 'alice', 'execute');
SELECT FALSE AS expected, has_perm('/ab/c', 'alice', 'execute');
SELECT FALSE AS expected, has_perm('/ab/cd', 'alice', 'execute');
SELECT FALSE AS expected, has_perm('/ab/c/d', 'alice', 'execute');

-- These permission answers should not.
SELECT TRUE AS expected, has_perm('/a', 'alice', 'execute');
SELECT FALSE AS expected, has_perm('/a', 'alice', 'delete');
SELECT FALSE AS expected, has_perm('/a/b', 'alice', 'execute');
SELECT TRUE AS expected, has_perm('/a/b/c', 'alice', 'execute');
SELECT TRUE AS expected, has_perm('/a/b/c/d', 'alice', 'execute');
SELECT FALSE AS expected, has_perm('/a/b/c/d', 'alice', 'delete');
