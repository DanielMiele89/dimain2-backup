CREATE TABLE [Staging].[Poland_ING_BIN_Agg_2021_updated] (
    [cpd]        DATETIME     NULL,
    [is_cnp]     BIT          NULL,
    [issuer_bin] INT          NULL,
    [mcc]        SMALLINT     NULL,
    [mcg]        SMALLINT     NULL,
    [mer_id]     VARCHAR (20) NULL,
    [mer_name]   VARCHAR (50) NULL,
    [pv_pln]     REAL         NULL,
    [tx]         INT          NULL,
    [cpd_ym]     INT          NULL
);

