CREATE TABLE [dbo].[MSSQL_DroppedLedgerHistory_MSSQL_LedgerHistoryFor_110623437_B0E1D33336ED4E3EABDB09ADAED603DE] (
    [Hierarchy1_ID]                INT           NOT NULL,
    [Hierarchy1_Code]              VARCHAR (255) NULL,
    [Hierarchy1_Name]              VARCHAR (255) NULL,
    [ledger_start_transaction_id]  BIGINT        NOT NULL,
    [ledger_end_transaction_id]    BIGINT        NULL,
    [ledger_start_sequence_number] BIGINT        NOT NULL,
    [ledger_end_sequence_number]   BIGINT        NULL
);
GO

