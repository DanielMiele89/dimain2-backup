CREATE TABLE [Relational].[Customer] (
    [FanID]             INT          NOT NULL,
    [CompositeID]       BIGINT       NULL,
    [SourceUID]         VARCHAR (20) NULL,
    [ClubID]            SMALLINT     NULL,
    [Gender]            CHAR (1)     NULL,
    [DOB]               DATE         NULL,
    [PostCode]          VARCHAR (10) NULL,
    [PostalSector]      VARCHAR (6)  NULL,
    [PostAreaCode]      VARCHAR (2)  NULL,
    [Region]            VARCHAR (30) NULL,
    [RegistrationDate]  DATETIME     NULL,
    [Status]            BIT          NULL,
    [AgeCurrent]        TINYINT      NULL,
    [ClubCashPending]   SMALLMONEY   NULL,
    [ClubCashAvailable] SMALLMONEY   NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC) WITH (DATA_COMPRESSION = PAGE)
);


GO
CREATE NONCLUSTERED INDEX [IDX_CID]
    ON [Relational].[Customer]([CompositeID] ASC) WITH (DATA_COMPRESSION = PAGE)
    ON [nFI_Indexes];


GO
CREATE NONCLUSTERED INDEX [IDX_SUID]
    ON [Relational].[Customer]([SourceUID] ASC) WITH (DATA_COMPRESSION = PAGE)
    ON [nFI_Indexes];


GO
CREATE NONCLUSTERED INDEX [IDX_CLID]
    ON [Relational].[Customer]([ClubID] ASC) WITH (DATA_COMPRESSION = PAGE)
    ON [nFI_Indexes];


GO
DENY ALTER
    ON OBJECT::[Relational].[Customer] TO [OnCall]
    AS [dbo];


GO
DENY DELETE
    ON OBJECT::[Relational].[Customer] TO [OnCall]
    AS [dbo];

