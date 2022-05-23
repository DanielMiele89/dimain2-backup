CREATE TABLE [dbo].[CBP_TSYS_CINMerger] (
    [SecondaryFanID]      INT      NOT NULL,
    [MasterFanID]         INT      NOT NULL,
    [FirstNameMatch]      TINYINT  NOT NULL,
    [LastNameMatch]       TINYINT  NOT NULL,
    [FullNameBonus]       AS       (CONVERT([tinyint],case when [FirstNameMatch]=(3) AND [LastNameMatch]=(3) then (3) when [FirstNameMatch]=(0) OR [LastNameMatch]=(0) then (0) else (2) end)),
    [DOBMatch]            TINYINT  NOT NULL,
    [AddressMatch]        TINYINT  NOT NULL,
    [PostCodeMatch]       TINYINT  NOT NULL,
    [OtherDetailBonus]    AS       (CONVERT([tinyint],case when [DOBMatch]=(0) OR [AddressMatch]=(0) OR [PostCodeMatch]=(0) then (0) else (2) end)),
    [TotalMatchScore]     AS       (((((([FirstNameMatch]+[LastNameMatch])+CONVERT([tinyint],case when [FirstNameMatch]=(3) AND [LastNameMatch]=(3) then (3) when [FirstNameMatch]=(0) OR [LastNameMatch]=(0) then (0) else (2) end))+[DOBMatch])+[AddressMatch])+[PostCodeMatch])+CONVERT([tinyint],case when [DOBMatch]=(0) OR [AddressMatch]=(0) OR [PostCodeMatch]=(0) then (0) else (2) end)),
    [DateMatchIdentified] DATETIME NOT NULL,
    [DateMerged]          DATETIME NULL,
    [DateMatchConfirmed]  DATETIME NULL,
    [MatchConfirmed]      TINYINT  NULL,
    CONSTRAINT [PK_CBP_TSYS_CINMerger] PRIMARY KEY CLUSTERED ([SecondaryFanID] ASC, [MasterFanID] ASC, [DateMatchIdentified] ASC)
);

