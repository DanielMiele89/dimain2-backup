CREATE TABLE [Staging].[PANlessTrans_To_SchemeTrans_DateLog] (
    [ID]                        INT      IDENTITY (1, 1) NOT NULL,
    [ImportedToPANlessDateTime] DATETIME NOT NULL,
    [LoggedDateTime]            DATETIME NOT NULL,
    CONSTRAINT [PK_PANlessTrans_To_SchemeTrans_DateLog] PRIMARY KEY CLUSTERED ([ImportedToPANlessDateTime] ASC)
);

