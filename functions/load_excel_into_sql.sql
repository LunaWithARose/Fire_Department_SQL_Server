-- ✅ Show secure_file_priv (tells you where MySQL allows file imports)
SHOW VARIABLES LIKE 'secure_file_priv';

-- ✅ Drop existing table to avoid conflicts
DROP TABLE IF EXISTS fire_dep2;

-- ✅ Create the fire_dep2 table with schema
CREATE TABLE fire_dep2 (
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
    City                            VARCHAR(25),
    Zip                             VARCHAR(20),
    EMDCode                         VARCHAR(20),
    FinalCallPriority               VARCHAR(5),
    InitialCallPriority             VARCHAR(5),
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
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/January 2024 - practice.csv'
INTO TABLE fire_dep2
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
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
    LatitudeY,
    LongitudeX,
    Location,
    Qualifier,
    City,
    Zip,
    EMDCode,
    FinalCallPriority,
    InitialCallPriority,
    CreateDatetime,
    StartDatetime,
    DispatchDateTime,
    EnrouteDateTime,
    ArriveDateTime,
    AtPatientDatetime,
    TransportDatetime,
    AtHospitalDatetime,
    TransferOfPatientCareTimeStamp,
    DepartHospitalDatetime,
    ClearDateTime,
    Round,
    `DispatchTime(Sec)`,
    `TurnoutTime(Sec)`,
    `TravelTime(Sec)`,
    `DispatchToArrival(Sec)`,
    `TotalResponseTime(Sec)`,
    `TotalCallTime(Sec)`,
    `TransportTime(Sec)`,
    `HospitalDropOffTime(Sec)`,
    `DispatchToAtPatient(Sec)`,
    `ArrivalToAtPatient(Sec)`,
    StartDateHour,
    StartDateDay,
    StartDateMonth,
    StartDateYear,
    IncidentFilter,
    CallFilter
);