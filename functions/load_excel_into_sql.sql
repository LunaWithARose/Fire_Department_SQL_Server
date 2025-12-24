-- ✅ Show secure_file_priv (tells you where MySQL allows file imports)
SHOW VARIABLES LIKE 'secure_file_priv';

-- ✅ Drop existing table to avoid conflicts
DROP TABLE IF EXISTS fire_dep;

-- ✅ Create the fire_dep2 table with schema
CREATE TABLE fire_dep (
    CallID                          VARCHAR(30),
    UnitNumber                      VARCHAR(10),
    ArrivalOrder                    VARCHAR(10),
    CallGEOFDID                     VARCHAR(20),
    CallGEODepartment               VARCHAR(100),
    CallGEOPoliceDept               VARCHAR(100),
    IncidentNumber                  VARCHAR(14),
    FDID                            VARCHAR(20),
    Department                      VARCHAR(50),
    FinalCallType                   VARCHAR(10),
    InitialCallType                 VARCHAR(10),
    IncidentType                    VARCHAR(50),
    Quadrant                        VARCHAR(30),
    Station                         VARCHAR(15),
    LatitudeY                       DECIMAL(10,6),
    LongitudeX                      DECIMAL(10,6),
    Location                        VARCHAR(150),
    Qualifier                       VARCHAR(30),
    City                            VARCHAR(40),
    Zip                             VARCHAR(20),
    EMDCode                         VARCHAR(20),
    FinalCallPriority               VARCHAR(10),
    InitialCallPriority             VARCHAR(10),
    CreateDatetime                  DATETIME,
    StartDatetime                   DATETIME,
    DispatchDateTime                DATETIME,
    EnrouteDateTime                 DATETIME,
    ArriveDateTime                  DATETIME,
    AtPatientDatetime               DATETIME,
    TransportDatetime               DATETIME,
    AtHospitalDatetime              DATETIME,
    TransferOfPatientCareTimeStamp  DATETIME,
    DepartHospitalDatetime          DATETIME,
    ClearDateTime                   DATETIME,
    Round                           INT,
    `DispatchTime(Sec)`             INT,
    `TurnoutTime(Sec)`              INT,
    `TravelTime(Sec)`               INT,
    `DispatchToArrival(Sec)`        INT,
    `TotalResponseTime(Sec)`        INT,
    `TotalCallTime(Sec)`            INT,
    `TransportTime(Sec)`            INT,
    `HospitalDropOffTime(Sec)`      INT,
    `DispatchToAtPatient(Sec)`      INT,
    `ArrivalToAtPatient(Sec)`       INT,
    StartDateHour                   INT,
    StartDateDay                    VARCHAR(20),
    StartDateMonth                  VARCHAR(20),   -- January, February, etc.
    StartDateYear                   INT,
    IncidentFilter                  VARCHAR(25),
    CallFilter                      VARCHAR(25)
);

-- ✅ Bulk load CSV file
-- NOTE: file must be inside the folder shown in secure_file_priv
-- If you want to load from anywhere, use LOAD DATA LOCAL INFILE instead
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/2025-12-05_FireCADData.csv'
INTO TABLE fire_dep
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    -- VARCHAR (safe to load directly)
    CallID,
    UnitNumber,
    ArrivalOrder,
    CallGEOFDID,
    CallGEODepartment,
    CallGEOPoliceDept,
    IncidentNumber,
    FDID,
    Department,
    FinalCallType,
    InitialCallType,
    IncidentType,
    Quadrant,
    Station,

    -- DECIMAL
    @LatitudeY,
    @LongitudeX,

    -- VARCHAR
    Location,
    Qualifier,
    City,
    Zip,
    EMDCode,
    FinalCallPriority,
    InitialCallPriority,

    -- DATETIME
    @CreateDatetime,
    @StartDatetime,
    @DispatchDateTime,
    @EnrouteDateTime,
    @ArriveDateTime,
    @AtPatientDatetime,
    @TransportDatetime,
    @AtHospitalDatetime,
    @TransferOfPatientCareTimeStamp,
    @DepartHospitalDatetime,
    @ClearDateTime,

    -- INT
    @Round,
    @DispatchTime,
    @TurnoutTime,
    @TravelTime,
    @DispatchToArrival,
    @TotalResponseTime,
    @TotalCallTime,
    @TransportTime,
    @HospitalDropOffTime,
    @DispatchToAtPatient,
    @ArrivalToAtPatient,

    -- DATE PARTS
    @StartDateHour,
    StartDateDay,
    StartDateMonth,
    @StartDateYear,

    -- VARCHAR
    IncidentFilter,
    CallFilter
)
SET
    -- DECIMAL
    LatitudeY  = NULLIF(@LatitudeY, ''),
    LongitudeX = NULLIF(@LongitudeX, ''),

    -- DATETIME
    CreateDatetime                 = NULLIF(@CreateDatetime, ''),
    StartDatetime                  = NULLIF(@StartDatetime, ''),
    DispatchDateTime               = NULLIF(@DispatchDateTime, ''),
    EnrouteDateTime                = NULLIF(@EnrouteDateTime, ''),
    ArriveDateTime                 = NULLIF(@ArriveDateTime, ''),
    AtPatientDatetime              = NULLIF(@AtPatientDatetime, ''),
    TransportDatetime              = NULLIF(@TransportDatetime, ''),
    AtHospitalDatetime             = NULLIF(@AtHospitalDatetime, ''),
    TransferOfPatientCareTimeStamp = NULLIF(@TransferOfPatientCareTimeStamp, ''),
    DepartHospitalDatetime         = NULLIF(@DepartHospitalDatetime, ''),
    ClearDateTime                  = NULLIF(@ClearDateTime, ''),

    -- INT (response + metadata)
    Round                          = NULLIF(@Round, ''),
    `DispatchTime(Sec)`             = NULLIF(@DispatchTime, ''),
    `TurnoutTime(Sec)`              = NULLIF(@TurnoutTime, ''),
    `TravelTime(Sec)`               = NULLIF(@TravelTime, ''),
    `DispatchToArrival(Sec)`        = NULLIF(@DispatchToArrival, ''),
    `TotalResponseTime(Sec)`        = NULLIF(@TotalResponseTime, ''),
    `TotalCallTime(Sec)`            = NULLIF(@TotalCallTime, ''),
    `TransportTime(Sec)`            = NULLIF(@TransportTime, ''),
    `HospitalDropOffTime(Sec)`      = NULLIF(@HospitalDropOffTime, ''),
    `DispatchToAtPatient(Sec)`      = NULLIF(@DispatchToAtPatient, ''),
    `ArrivalToAtPatient(Sec)`       = NULLIF(@ArrivalToAtPatient, ''),
    StartDateHour                   = NULLIF(@StartDateHour, ''),
    StartDateYear                   = NULLIF(@StartDateYear, '');



