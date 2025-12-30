DROP TABLE IF EXISTS unit_staffing;
CREATE TABLE unit_staffing(unit_prefix VARCHAR(4), firefighters_per_unit INT);

INSERT INTO unit_staffing (unit_prefix, firefighters_per_unit)
VALUES
    ('E', 3),     -- Engine
    ('KCE', 3),   -- King County
    ('L', 3),     -- Ladder
    ('KCL', 3),   -- King County Ladder
    ('T', 1),     -- Tenders
    ('BR', 2),    -- Brush
    ('KCBR', 3),  -- King County Brush
    ('M', 2),
    ('A', 2),
    ('CH', 1),
    ('DC', 1),
    ('LT', 1)
    
    