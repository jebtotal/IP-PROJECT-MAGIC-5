-- S1-DBA-05: seed documented modules, roles, and rights.
-- Six rights absent from the source guide and superadmin account provisioning are deferred.
BEGIN;
SET LOCAL search_path = public, pg_temp;

INSERT INTO public.role (role_code, role_name)
VALUES
    ('superadmin', 'Superadmin'),
    ('admin', 'Admin'),
    ('user', 'User')
ON CONFLICT (role_code) DO NOTHING;

INSERT INTO public.module (module_code, module_name)
VALUES
    ('customers', 'Customer'),
    ('products', 'Product'),
    ('hr', 'Human Resources'),
    ('sales', 'Sales'),
    ('reports', 'Reports')
ON CONFLICT (module_code) DO NOTHING;

INSERT INTO public.right_catalog (right_code, module_code, resource_code, action)
VALUES
    ('customers.view', 'customers', 'customers', 'view'),
    ('customers.add', 'customers', 'customers', 'add'),
    ('customers.edit', 'customers', 'customers', 'edit'),
    ('customers.delete', 'customers', 'customers', 'delete'),
    ('products.view', 'products', 'products', 'view'),
    ('products.add', 'products', 'products', 'add'),
    ('products.edit', 'products', 'products', 'edit'),
    ('products.delete', 'products', 'products', 'delete'),
    ('hr.view', 'hr', 'hr', 'view'),
    ('hr.jobAdd', 'hr', 'jobs', 'add'),
    ('hr.jobEdit', 'hr', 'jobs', 'edit'),
    ('hr.jobDelete', 'hr', 'jobs', 'delete'),
    ('hr.deptAdd', 'hr', 'departments', 'add'),
    ('hr.deptEdit', 'hr', 'departments', 'edit'),
    ('hr.deptDelete', 'hr', 'departments', 'delete'),
    ('hr.empAdd', 'hr', 'employees', 'add'),
    ('hr.empEdit', 'hr', 'employees', 'edit'),
    ('hr.empDelete', 'hr', 'employees', 'delete'),
    ('sales.view', 'sales', 'sales', 'view'),
    ('sales.add', 'sales', 'sales', 'add'),
    ('sales.edit', 'sales', 'sales', 'edit'),
    ('sales.delete', 'sales', 'sales', 'delete'),
    ('reports.view', 'reports', 'reports', 'view'),
    ('sales.details.view', 'sales', 'sale_details', 'view'),
    ('sales.details.add', 'sales', 'sale_details', 'add'),
    ('sales.details.edit', 'sales', 'sale_details', 'edit'),
    ('sales.details.delete', 'sales', 'sale_details', 'delete'),
    ('hr.jobHistory.view', 'hr', 'job_history', 'view'),
    ('reports.topCustomers.view', 'reports', 'top_customers', 'view'),
    ('reports.productsMaster.view', 'reports', 'products_master', 'view')
ON CONFLICT (right_code) DO NOTHING;

DO $$
DECLARE
    missing_roles TEXT;
    missing_modules TEXT;
    missing_rights TEXT;
BEGIN
    SELECT string_agg(expected.role_code, ', ' ORDER BY expected.role_code)
      INTO missing_roles
      FROM (VALUES
          ('superadmin', 'Superadmin'),
          ('admin', 'Admin'),
          ('user', 'User')
      ) AS expected(role_code, role_name)
      LEFT JOIN public.role AS actual
        ON actual.role_code = expected.role_code
       AND actual.role_name = expected.role_name
     WHERE actual.role_code IS NULL;

    IF missing_roles IS NOT NULL THEN
        RAISE EXCEPTION 'S1-DBA-05 stopped: role seed conflicts with: %.', missing_roles;
    END IF;

    SELECT string_agg(expected.module_code, ', ' ORDER BY expected.module_code)
      INTO missing_modules
      FROM (VALUES
          ('customers', 'Customer'),
          ('products', 'Product'),
          ('hr', 'Human Resources'),
          ('sales', 'Sales'),
          ('reports', 'Reports')
      ) AS expected(module_code, module_name)
      LEFT JOIN public.module AS actual
        ON actual.module_code = expected.module_code
       AND actual.module_name = expected.module_name
     WHERE actual.module_code IS NULL;

    IF missing_modules IS NOT NULL THEN
        RAISE EXCEPTION 'S1-DBA-05 stopped: module seed conflicts with: %.', missing_modules;
    END IF;

    SELECT string_agg(expected.right_code, ', ' ORDER BY expected.right_code)
      INTO missing_rights
      FROM (VALUES
          ('customers.view', 'customers', 'customers', 'view'),
          ('customers.add', 'customers', 'customers', 'add'),
          ('customers.edit', 'customers', 'customers', 'edit'),
          ('customers.delete', 'customers', 'customers', 'delete'),
          ('products.view', 'products', 'products', 'view'),
          ('products.add', 'products', 'products', 'add'),
          ('products.edit', 'products', 'products', 'edit'),
          ('products.delete', 'products', 'products', 'delete'),
          ('hr.view', 'hr', 'hr', 'view'),
          ('hr.jobAdd', 'hr', 'jobs', 'add'),
          ('hr.jobEdit', 'hr', 'jobs', 'edit'),
          ('hr.jobDelete', 'hr', 'jobs', 'delete'),
          ('hr.deptAdd', 'hr', 'departments', 'add'),
          ('hr.deptEdit', 'hr', 'departments', 'edit'),
          ('hr.deptDelete', 'hr', 'departments', 'delete'),
          ('hr.empAdd', 'hr', 'employees', 'add'),
          ('hr.empEdit', 'hr', 'employees', 'edit'),
          ('hr.empDelete', 'hr', 'employees', 'delete'),
          ('sales.view', 'sales', 'sales', 'view'),
          ('sales.add', 'sales', 'sales', 'add'),
          ('sales.edit', 'sales', 'sales', 'edit'),
          ('sales.delete', 'sales', 'sales', 'delete'),
          ('reports.view', 'reports', 'reports', 'view'),
          ('sales.details.view', 'sales', 'sale_details', 'view'),
          ('sales.details.add', 'sales', 'sale_details', 'add'),
          ('sales.details.edit', 'sales', 'sale_details', 'edit'),
          ('sales.details.delete', 'sales', 'sale_details', 'delete'),
          ('hr.jobHistory.view', 'hr', 'job_history', 'view'),
          ('reports.topCustomers.view', 'reports', 'top_customers', 'view'),
          ('reports.productsMaster.view', 'reports', 'products_master', 'view')
      ) AS expected(right_code, module_code, resource_code, action)
      LEFT JOIN public.right_catalog AS actual
        ON actual.right_code = expected.right_code
       AND actual.module_code = expected.module_code
       AND actual.resource_code = expected.resource_code
       AND actual.action = expected.action
     WHERE actual.right_code IS NULL;

    IF missing_rights IS NOT NULL THEN
        RAISE EXCEPTION 'S1-DBA-05 stopped: right seed conflicts with: %.', missing_rights;
    END IF;
END;
$$;

COMMIT;
