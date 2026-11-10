-- Masking rules: the only file you need to edit.
-- One block per column: which table.column to mask, and how.
--
-- * Don't mask primary or foreign key columns, or joins in the dump will break.
-- * A column with no rule here goes into the dump UNMASKED.
-- * Use random masks (fake_*), not pseudo_*: they give a different fake value on
--   every row and every run, so nothing can be traced back to the real value.
--
-- Common masks:
--   anon.fake_first_name()   anon.fake_last_name()   anon.fake_email()
--   anon.fake_address()      anon.fake_postcode()    anon.random_phone()
--   VALUE NULL               VALUE $$REDACTED$$

-- customer
SECURITY LABEL FOR anon ON COLUMN customer.first_name
  IS 'MASKED WITH FUNCTION anon.fake_first_name()';
SECURITY LABEL FOR anon ON COLUMN customer.last_name
  IS 'MASKED WITH FUNCTION anon.fake_last_name()';
SECURITY LABEL FOR anon ON COLUMN customer.email
  IS 'MASKED WITH FUNCTION anon.fake_email()';
