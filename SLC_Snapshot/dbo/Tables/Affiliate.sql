CREATE TABLE [dbo].[Affiliate] (
    [ID]                     INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Name]                   NVARCHAR (50) NOT NULL,
    [Password]               NVARCHAR (20) NOT NULL,
    [AnniversaryDate]        DATETIME      NOT NULL,
    [CurrentCommissionShare] FLOAT (53)    NOT NULL,
    [Status]                 BIT           NOT NULL,
    [ClubID]                 INT           NULL,
    [IsLive]                 BIT           NOT NULL,
    [IsControlCell]          BIT           NULL,
    CONSTRAINT [PK_Affiliate] PRIMARY KEY CLUSTERED ([ID] ASC)
);

