﻿CREATE TABLE [Staging].[Customer] (
    [FanID]                   INT           NOT NULL,
    [Status]                  INT           NOT NULL,
    [SourceUID]               VARCHAR (20)  NULL,
    [DOB]                     DATE          NULL,
    [Title]                   VARCHAR (20)  NULL,
    [FirstName]               VARCHAR (50)  NULL,
    [LastName]                VARCHAR (50)  NULL,
    [Address1]                VARCHAR (100) NULL,
    [Address2]                VARCHAR (100) NULL,
    [City]                    VARCHAR (100) NULL,
    [County]                  VARCHAR (100) NULL,
    [PostCode]                VARCHAR (10)  NULL,
    [Email]                   VARCHAR (100) NULL,
    [AgreedTCsDate]           DATE          NULL,
    [OfflineOnly]             BIT           NULL,
    [ContactByPost]           BIT           NULL,
    [Unsubscribed]            BIT           NULL,
    [Hardbounced]             BIT           NULL,
    [CompositeID]             BIGINT        NULL,
    [Primacy]                 CHAR (1)      NULL,
    [IsJoint]                 BIT           NULL,
    [ControlGroupNumber]      TINYINT       NULL,
    [ReportGroup]             TINYINT       NULL,
    [TreatmentGroup]          TINYINT       NULL,
    [LaunchGroup]             CHAR (4)      NULL,
    [OriginalEmailPermission] BIT           NULL,
    [OriginalDMPermission]    BIT           NULL,
    [EmailOriginallySupplied] BIT           NULL,
    [AgeCurrent]              TINYINT       NULL,
    [AgeCurrentBandNumber]    TINYINT       NULL,
    [AgeCurrentBandText]      VARCHAR (10)  NULL,
    [Gender]                  CHAR (1)      NULL,
    [PostalSector]            VARCHAR (6)   NULL,
    [PostCodeDistrict]        VARCHAR (4)   NULL,
    [PostArea]                VARCHAR (2)   NULL,
    [Region]                  VARCHAR (30)  NULL,
    [EmailStructureValid]     BIT           NULL,
    [MarketableByEmail]       BIT           NULL,
    [MarketableByDirectMail]  BIT           NULL,
    [EmailNonOpener]          BIT           NULL,
    [MobileTelephone]         NVARCHAR (50) NOT NULL,
    [ValidMobile]             BIT           NULL,
    [Salutation]              VARCHAR (100) NULL,
    [CurrentEmailPermission]  BIT           NULL,
    [CurrentDMPermission]     BIT           NULL,
    [ClubID]                  INT           NULL,
    [DeactivatedDate]         DATE          NULL,
    [OptedOutDate]            DATE          NULL,
    [CurrentlyActive]         BIT           NULL,
    [POC_Customer]            BIT           NULL,
    [Rainbow_Customer]        BIT           NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC) WITH (FILLFACTOR = 75, DATA_COMPRESSION = PAGE)
);




GO
DENY SELECT
    ON OBJECT::[Staging].[Customer] TO [New_PIIRemoved]
    AS [dbo];

