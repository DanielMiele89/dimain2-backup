CREATE TABLE [Relational].[Customer] (
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
    [ClubID]                  INT           NULL,
    [DeactivatedDate]         DATE          NULL,
    [OptedOutDate]            DATE          NULL,
    [CurrentlyActive]         BIT           NULL,
    [POC_Customer]            BIT           NULL,
    [Rainbow_Customer]        BIT           NULL,
    [Registered]              BIT           NULL,
    CONSTRAINT [pk_FanID] PRIMARY KEY CLUSTERED ([FanID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [i_SourceUID]
    ON [Relational].[Customer]([SourceUID] ASC)
    INCLUDE([CurrentlyActive], [FanID], [Status]) WITH (FILLFACTOR = 90)
    ON [Warehouse_Indexes];


GO
CREATE NONCLUSTERED INDEX [i_CompositeID]
    ON [Relational].[Customer]([CompositeID] ASC)
    INCLUDE([SourceUID], [FanID], [CurrentlyActive], [ActivatedDate]) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [i_PostArea]
    ON [Relational].[Customer]([PostArea] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_MBE]
    ON [Relational].[Customer]([MarketableByEmail] ASC, [FanID] ASC)
    INCLUDE([SourceUID], [ActivatedDate]) WITH (FILLFACTOR = 75);


GO
CREATE NONCLUSTERED INDEX [IDX_CA]
    ON [Relational].[Customer]([CurrentlyActive] ASC)
    INCLUDE([PostArea], [DOB], [FanID], [SourceUID]);


GO
CREATE NONCLUSTERED INDEX [ix_MBE_CA]
    ON [Relational].[Customer]([MarketableByEmail] ASC, [CurrentlyActive] ASC, [SourceUID] ASC)
    INCLUDE([FanID], [Gender], [PostCode], [Region], [AgeCurrent]) WITH (FILLFACTOR = 75);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff]
    ON [Relational].[Customer]([MarketableByEmail] ASC, [ActivatedDate] ASC, [FanID] ASC) WITH (FILLFACTOR = 75);


GO
CREATE NONCLUSTERED INDEX [ix_Newstuff]
    ON [Relational].[Customer]([DeactivatedDate] ASC)
    INCLUDE([FanID], [CompositeID]) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_MarketableActive_IncMany]
    ON [Relational].[Customer]([MarketableByEmail] ASC, [CurrentlyActive] ASC)
    INCLUDE([FanID], [CompositeID], [Gender], [PostCode], [AgeCurrent], [ClubID]);


GO
CREATE NONCLUSTERED INDEX [IX_CurrentlyActive_IncComposite]
    ON [Relational].[Customer]([CurrentlyActive] ASC)
    INCLUDE([CompositeID]);

