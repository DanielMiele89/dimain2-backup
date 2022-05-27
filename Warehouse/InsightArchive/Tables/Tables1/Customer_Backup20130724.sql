﻿CREATE TABLE [InsightArchive].[Customer_Backup20130724] (
    [FanID]                   INT           NOT NULL,
    [SourceUID]               VARCHAR (20)  NULL,
    [CompositeID]             BIGINT        NULL,
    [Status]                  INT           NOT NULL,
    [Gender]                  CHAR (1)      NULL,
    [Title]                   VARCHAR (20)  NULL,
    [FirstName]               VARCHAR (50)  NULL,
    [LastName]                VARCHAR (50)  NULL,
    [Salutation]              VARCHAR (100) NULL,
    [Address1]                VARCHAR (100) NULL,
    [Address2]                VARCHAR (100) NULL,
    [City]                    VARCHAR (100) NULL,
    [County]                  VARCHAR (100) NULL,
    [PostCode]                VARCHAR (10)  NULL,
    [PostalSector]            VARCHAR (6)   NULL,
    [PostCodeDistrict]        VARCHAR (4)   NULL,
    [PostArea]                VARCHAR (2)   NULL,
    [Region]                  VARCHAR (30)  NULL,
    [Email]                   VARCHAR (100) NULL,
    [Unsubscribed]            BIT           NULL,
    [Hardbounced]             BIT           NULL,
    [EmailStructureValid]     BIT           NULL,
    [MobileTelephone]         NVARCHAR (50) NOT NULL,
    [ValidMobile]             BIT           NULL,
    [Primacy]                 CHAR (1)      NULL,
    [IsJoint]                 BIT           NULL,
    [ControlGroupNumber]      TINYINT       NULL,
    [IsControl]               BIT           NULL,
    [ReportGroup]             TINYINT       NULL,
    [TreatmentGroup]          TINYINT       NULL,
    [LaunchGroup]             CHAR (4)      NULL,
    [Activated]               BIT           NULL,
    [ActivatedDate]           DATE          NULL,
    [ActivatedOffline]        BIT           NULL,
    [MarketableByEmail]       BIT           NULL,
    [MarketableByDirectMail]  BIT           NULL,
    [EmailNonOpener]          BIT           NULL,
    [OriginalEmailPermission] BIT           NULL,
    [OriginalDMPermission]    BIT           NULL,
    [EmailOriginallySupplied] BIT           NULL,
    [CurrentEmailPermission]  BIT           NULL,
    [CurrentDMPermission]     BIT           NULL,
    [DOB]                     DATE          NULL,
    [AgeCurrent]              TINYINT       NULL,
    [AgeCurrentBandNumber]    TINYINT       NULL,
    [AgeCurrentBandText]      VARCHAR (10)  NULL,
    [AgeAtLaunch]             TINYINT       NULL,
    [AgeAtLaunchBandNumber]   TINYINT       NULL,
    [AgeAtLaunchBandText]     VARCHAR (10)  NULL,
    [ClubID]                  INT           NULL,
    [DeactivatedDate]         DATE          NULL,
    [OptedOutDate]            DATE          NULL
);




GO
DENY SELECT
    ON OBJECT::[InsightArchive].[Customer_Backup20130724] TO [New_PIIRemoved]
    AS [dbo];

