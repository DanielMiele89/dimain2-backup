CREATE TABLE [Relational].[CashbackPlusEmailAcquisition] (
    [CIN]          BIGINT        NULL,
    [SourceUID]    NVARCHAR (20) NULL,
    [Day_Flag]     NVARCHAR (10) NULL,
    [Date]         DATE          NULL,
    [NotDelivered] CHAR (1)      NULL,
    [Delivered]    CHAR (1)      NULL,
    [Opened]       CHAR (1)      NULL,
    [Bank]         INT           NULL,
    [KeyCode]      CHAR (50)     NULL,
    [Subject_L]    CHAR (50)     NULL,
    [I_D]          INT           IDENTITY (1, 1) NOT NULL,
    PRIMARY KEY CLUSTERED ([I_D] ASC)
);

