CREATE TABLE [Staging].[Reward_StaffTable] (
    [StaffID]         INT           IDENTITY (1, 1) NOT NULL,
    [FirstName]       VARCHAR (50)  NULL,
    [Surname]         VARCHAR (100) NULL,
    [Active]          BIT           NOT NULL,
    [JobTitle]        VARCHAR (50)  NULL,
    [DeskTelephone]   VARCHAR (25)  NULL,
    [MobileTelephone] VARCHAR (25)  NULL,
    [ContactEmail]    VARCHAR (150) NULL,
    PRIMARY KEY CLUSTERED ([StaffID] ASC)
);

