CREATE TABLE [MI].[RBSMIPortal_DDException] (
    [ID]                INT           IDENTITY (1, 1) NOT NULL,
    [ClubID]            INT           NOT NULL,
    [CIN]               VARCHAR (50)  NOT NULL,
    [FanID]             INT           NOT NULL,
    [TransactionDate]   DATE          NOT NULL,
    [SMonth]            DATETIME      NULL,
    [OIN]               INT           NOT NULL,
    [Narrative]         NVARCHAR (18) NOT NULL,
    [TransactionAmount] MONEY         NOT NULL,
    CONSTRAINT [PK_MI_RBSMIPortal_DDException] PRIMARY KEY CLUSTERED ([ID] ASC)
);

