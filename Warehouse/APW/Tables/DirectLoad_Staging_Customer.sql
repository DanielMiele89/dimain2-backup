CREATE TABLE [APW].[DirectLoad_Staging_Customer] (
    [FanID]            INT      NOT NULL,
    [CustStatus]       INT      NOT NULL,
    [DOB]              DATE     NULL,
    [Gender]           CHAR (1) NOT NULL,
    [ActivationDate]   DATE     NOT NULL,
    [DeactivationDate] DATE     NULL,
    CONSTRAINT [APW_DirectLoad_Staging_Customer] PRIMARY KEY CLUSTERED ([FanID] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE)
);

