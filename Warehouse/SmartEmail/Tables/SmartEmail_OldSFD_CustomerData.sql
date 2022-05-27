CREATE TABLE [SmartEmail].[SmartEmail_OldSFD_CustomerData] (
    [Email]                 NVARCHAR (100) NOT NULL,
    [ClubID]                INT            NOT NULL,
    [Title]                 NVARCHAR (20)  NULL,
    [FirstName]             NVARCHAR (50)  NULL,
    [Lastname]              NVARCHAR (50)  NULL,
    [partial postcode]      VARCHAR (4)    NULL,
    [ActivationChannel]     INT            NOT NULL,
    [RegistrationLink]      NVARCHAR (200) NULL,
    [customer id]           INT            NOT NULL,
    [CustomerJourneyStatus] VARCHAR (3)    NOT NULL,
    [CJS]                   VARCHAR (3)    NOT NULL,
    [WeekNumber]            BIT            NOT NULL,
    [IsRegistered]          BIT            NOT NULL,
    [AgreedTcsDate]         DATETIME       NOT NULL,
    [dob]                   DATE           NOT NULL,
    [ClubCashPending]       SMALLMONEY     NOT NULL,
    [ClubCashAvailable]     SMALLMONEY     NOT NULL,
    [LastAddedCard]         DATE           NULL,
    [WelcomeCode]           VARCHAR (2)    NULL,
    PRIMARY KEY CLUSTERED ([customer id] ASC)
);

