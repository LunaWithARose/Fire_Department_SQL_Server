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
    ('M', 2),     -- Medic
    ('A', 2),     -- Aid
    ('CH', 1),    -- Chief
    ('DC', 1),    -- Deputy Chief
    ('LT', 1)     -- I cant spell this right now 
    
    