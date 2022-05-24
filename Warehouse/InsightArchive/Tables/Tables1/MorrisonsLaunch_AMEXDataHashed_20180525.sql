CREATE TABLE [InsightArchive].[MorrisonsLaunch_AMEXDataHashed_20180525] (
    [ID_AMEX]                 BIGINT        NULL,
    [FirstNameHashed_AMEX]    VARCHAR (100) NULL,
    [SurnameHashed_AMEX]      VARCHAR (100) NULL,
    [AddressLine1Hashed_AMEX] VARCHAR (100) NULL,
    [PostCodeHashed_AMEX]     VARCHAR (100) NULL,
    [EmailHashed_AMEX]        VARCHAR (100) NULL
);


GO
CREATE CLUSTERED INDEX [IDX_MorrisonsLaunch_AMEX_Email]
    ON [InsightArchive].[MorrisonsLaunch_AMEXDataHashed_20180525]([EmailHashed_AMEX] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);

