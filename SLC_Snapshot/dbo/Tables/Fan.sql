CREATE TABLE [dbo].[Fan] (
    [ID]                    INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [ClubID]                INT            NOT NULL,
    [Title]                 NVARCHAR (20)  NULL,
    [Email]                 NVARCHAR (100) NOT NULL,
    [FirstName]             NVARCHAR (50)  NOT NULL,
    [LastName]              NVARCHAR (50)  NOT NULL,
    [Sex]                   TINYINT        NOT NULL,
    [DOB]                   DATETIME       NOT NULL,
    [Address1]              NVARCHAR (100) NOT NULL,
    [Address2]              NVARCHAR (100) NOT NULL,
    [City]                  NVARCHAR (100) NOT NULL,
    [Postcode]              NVARCHAR (20)  NOT NULL,
    [County]                NVARCHAR (100) NOT NULL,
    [RegistrationDate]      DATETIME       NOT NULL,
    [PointsPending]         INT            NOT NULL,
    [PointsAvailable]       INT            NOT NULL,
    [Status]                INT            NOT NULL,
    [Telephone]             NVARCHAR (50)  NOT NULL,
    [MobileTelephone]       NVARCHAR (50)  NOT NULL,
    [SourceUID]             VARCHAR (20)   NULL,
    [Country]               NVARCHAR (80)  NULL,
    [Unsubscribed]          BIT            NOT NULL,
    [HardBounced]           BIT            NOT NULL,
    [ContactByEmail_old]    BIT            NOT NULL,
    [ContactByPhone]        BIT            NOT NULL,
    [ContactBySMS]          BIT            NOT NULL,
    [EmailFormatHTML]       BIT            NOT NULL,
    [OnlineOnly]            BIT            NULL,
    [UserName]              NVARCHAR (20)  NULL,
    [ClubCashPending]       SMALLMONEY     NOT NULL,
    [ClubCashAvailable]     SMALLMONEY     NOT NULL,
    [CompositeID]           BIGINT         NULL,
    [ContactByPost]         BIT            NULL,
    [AgreedTCs]             BIT            NULL,
    [AgreedTCsDate]         DATETIME       NULL,
    [OfflineOnly]           BIT            NULL,
    [DeceasedDate]          DATE           NULL,
    [OptOut]                BIT            NOT NULL,
    [CustomerJourneyStatus] VARCHAR (3)    NULL,
    [ActivationChannel]     TINYINT        NOT NULL,
    CONSTRAINT [PK_Fan] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ix_ClubID_ID]
    ON [dbo].[Fan]([ClubID] ASC, [ID] ASC)
    INCLUDE([Email], [AgreedTCs], [AgreedTCsDate], [Unsubscribed]) WITH (FILLFACTOR = 70)
    ON [SLC_REPL_Indexes];


GO
CREATE NONCLUSTERED INDEX [ix_ClubID_ID_2]
    ON [dbo].[Fan]([ClubID] ASC, [ID] ASC)
    INCLUDE([Sex], [DOB], [Postcode], [RegistrationDate], [Status], [SourceUID], [ClubCashPending], [ClubCashAvailable], [CompositeID]) WITH (FILLFACTOR = 70)
    ON [SLC_REPL_Indexes];


GO
CREATE NONCLUSTERED INDEX [ix_ClubID_Lastname]
    ON [dbo].[Fan]([ClubID] ASC, [LastName] ASC)
    INCLUDE([ID], [Email]) WITH (FILLFACTOR = 70)
    ON [SLC_REPL_Indexes];


GO
CREATE NONCLUSTERED INDEX [ix_CompositeID]
    ON [dbo].[Fan]([CompositeID] ASC)
    INCLUDE([ID], [ClubID]) WITH (FILLFACTOR = 70)
    ON [SLC_REPL_Indexes];


GO
CREATE NONCLUSTERED INDEX [ix_SourceUID]
    ON [dbo].[Fan]([SourceUID] ASC)
    INCLUDE([ID], [ClubID], [CompositeID], [Status]) WITH (FILLFACTOR = 70)
    ON [SLC_REPL_Indexes];


GO
CREATE NONCLUSTERED INDEX [ix_Status_AgreedTCs]
    ON [dbo].[Fan]([Status] ASC, [ClubID] ASC, [AgreedTCs] ASC)
    INCLUDE([ID], [SourceUID], [CompositeID], [AgreedTCsDate], [ClubCashPending], [ClubCashAvailable]) WITH (FILLFACTOR = 65)
    ON [SLC_REPL_Indexes];


GO
CREATE NONCLUSTERED INDEX [ix_Status_AgreedTCs02]
    ON [dbo].[Fan]([Status] ASC, [ClubID] ASC, [AgreedTCs] ASC, [OfflineOnly] ASC)
    INCLUDE([ID], [Email], [DeceasedDate], [AgreedTCsDate]) WITH (FILLFACTOR = 80)
    ON [SLC_REPL_Indexes];


GO
CREATE NONCLUSTERED INDEX [ix_Status_Dec]
    ON [dbo].[Fan]([Status] ASC, [DeceasedDate] ASC, [OfflineOnly] ASC)
    INCLUDE([ID], [ClubID], [Title], [Email], [FirstName], [LastName], [DOB], [Postcode], [AgreedTCsDate], [ActivationChannel]) WITH (FILLFACTOR = 70)
    ON [SLC_REPL_Indexes];


GO
CREATE NONCLUSTERED INDEX [sn_ACPPF]
    ON [dbo].[Fan]([Status] ASC, [ClubID] ASC)
    INCLUDE([ID], [PointsPending], [PointsAvailable], [ClubCashPending], [ClubCashAvailable]) WITH (FILLFACTOR = 65)
    ON [SLC_REPL_Indexes];


GO
CREATE TRIGGER TriggerFanUpdate on dbo.Fan
AFTER UPDATE
AS
BEGIN
	SET NOCOUNT ON;
	INSERT INTO dbo.Fan_Changes (FanID, [Action])
	SELECT 
		i.ID, 
		[Action] = 'U'
	FROM inserted i 
END

GO

CREATE TRIGGER TriggerFanInsert on dbo.Fan
AFTER INSERT
AS
BEGIN
	SET NOCOUNT ON;
	INSERT INTO dbo.Fan_Changes (FanID, [Action])
	SELECT 
		i.ID, 
		[Action] = 'I'
	FROM inserted i 
END
GO

CREATE TRIGGER [dbo].[TriggerFanDelete] on [dbo].[Fan]
AFTER delete
AS
BEGIN
	SET NOCOUNT ON;
	INSERT INTO dbo.Fan_Changes (FanID, [Action])
	SELECT 
		d.ID, 
		[Action] = 'D'
	FROM deleted d 
END
GO
GRANT SELECT
    ON OBJECT::[dbo].[Fan] TO [Analyst]
    AS [dbo];


GO
GRANT SELECT
    ON [dbo].[Fan] ([ID]) TO [PII_Removed]
    AS [dbo];


GO
GRANT SELECT
    ON [dbo].[Fan] ([ClubID]) TO [PII_Removed]
    AS [dbo];


GO
GRANT SELECT
    ON [dbo].[Fan] ([Title]) TO [PII_Removed]
    AS [dbo];


GO
GRANT SELECT
    ON [dbo].[Fan] ([Email]) TO [PII_Removed]
    AS [dbo];


GO
GRANT SELECT
    ON [dbo].[Fan] ([FirstName]) TO [PII_Removed]
    AS [dbo];


GO
GRANT SELECT
    ON [dbo].[Fan] ([LastName]) TO [PII_Removed]
    AS [dbo];


GO
GRANT SELECT
    ON [dbo].[Fan] ([Sex]) TO [PII_Removed]
    AS [dbo];


GO
GRANT SELECT
    ON [dbo].[Fan] ([DOB]) TO [PII_Removed]
    AS [dbo];


GO
GRANT SELECT
    ON [dbo].[Fan] ([Address1]) TO [PII_Removed]
    AS [dbo];


GO
GRANT SELECT
    ON [dbo].[Fan] ([Address2]) TO [PII_Removed]
    AS [dbo];


GO
GRANT SELECT
    ON [dbo].[Fan] ([City]) TO [PII_Removed]
    AS [dbo];


GO
GRANT SELECT
    ON [dbo].[Fan] ([Postcode]) TO [PII_Removed]
    AS [dbo];


GO
GRANT SELECT
    ON [dbo].[Fan] ([County]) TO [PII_Removed]
    AS [dbo];


GO
GRANT SELECT
    ON [dbo].[Fan] ([RegistrationDate]) TO [PII_Removed]
    AS [dbo];


GO
GRANT SELECT
    ON [dbo].[Fan] ([PointsPending]) TO [PII_Removed]
    AS [dbo];


GO
GRANT SELECT
    ON [dbo].[Fan] ([PointsAvailable]) TO [PII_Removed]
    AS [dbo];


GO
GRANT SELECT
    ON [dbo].[Fan] ([Status]) TO [PII_Removed]
    AS [dbo];


GO
GRANT SELECT
    ON [dbo].[Fan] ([Telephone]) TO [PII_Removed]
    AS [dbo];


GO
GRANT SELECT
    ON [dbo].[Fan] ([MobileTelephone]) TO [PII_Removed]
    AS [dbo];


GO
GRANT SELECT
    ON [dbo].[Fan] ([SourceUID]) TO [PII_Removed]
    AS [dbo];


GO
GRANT SELECT
    ON [dbo].[Fan] ([Country]) TO [PII_Removed]
    AS [dbo];


GO
GRANT SELECT
    ON [dbo].[Fan] ([Unsubscribed]) TO [PII_Removed]
    AS [dbo];


GO
GRANT SELECT
    ON [dbo].[Fan] ([HardBounced]) TO [PII_Removed]
    AS [dbo];


GO
GRANT SELECT
    ON [dbo].[Fan] ([ContactByEmail_old]) TO [PII_Removed]
    AS [dbo];


GO
GRANT SELECT
    ON [dbo].[Fan] ([ContactByPhone]) TO [PII_Removed]
    AS [dbo];


GO
GRANT SELECT
    ON [dbo].[Fan] ([ContactBySMS]) TO [PII_Removed]
    AS [dbo];


GO
GRANT SELECT
    ON [dbo].[Fan] ([EmailFormatHTML]) TO [PII_Removed]
    AS [dbo];


GO
GRANT SELECT
    ON [dbo].[Fan] ([OnlineOnly]) TO [PII_Removed]
    AS [dbo];


GO
GRANT SELECT
    ON [dbo].[Fan] ([UserName]) TO [PII_Removed]
    AS [dbo];


GO
GRANT SELECT
    ON [dbo].[Fan] ([ClubCashPending]) TO [PII_Removed]
    AS [dbo];


GO
GRANT SELECT
    ON [dbo].[Fan] ([ClubCashAvailable]) TO [PII_Removed]
    AS [dbo];


GO
GRANT SELECT
    ON [dbo].[Fan] ([CompositeID]) TO [PII_Removed]
    AS [dbo];


GO
GRANT SELECT
    ON [dbo].[Fan] ([ContactByPost]) TO [PII_Removed]
    AS [dbo];


GO
GRANT SELECT
    ON [dbo].[Fan] ([AgreedTCs]) TO [PII_Removed]
    AS [dbo];


GO
GRANT SELECT
    ON [dbo].[Fan] ([AgreedTCsDate]) TO [PII_Removed]
    AS [dbo];


GO
GRANT SELECT
    ON [dbo].[Fan] ([OfflineOnly]) TO [PII_Removed]
    AS [dbo];


GO
GRANT SELECT
    ON [dbo].[Fan] ([DeceasedDate]) TO [PII_Removed]
    AS [dbo];


GO
GRANT SELECT
    ON [dbo].[Fan] ([OptOut]) TO [PII_Removed]
    AS [dbo];


GO
GRANT SELECT
    ON [dbo].[Fan] ([CustomerJourneyStatus]) TO [PII_Removed]
    AS [dbo];


GO
GRANT SELECT
    ON [dbo].[Fan] ([ActivationChannel]) TO [PII_Removed]
    AS [dbo];


GO
GRANT SELECT
    ON [dbo].[Fan] ([ID]) TO [Process_AWS_SpendEarn]
    AS [dbo];


GO
GRANT SELECT
    ON [dbo].[Fan] ([ClubID]) TO [Process_AWS_SpendEarn]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[Fan] TO [virgin_etl_user]
    AS [dbo];

