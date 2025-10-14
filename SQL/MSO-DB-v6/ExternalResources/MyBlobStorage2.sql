CREATE EXTERNAL DATA SOURCE [MyBlobStorage2]
    WITH (
    TYPE = BLOB_STORAGE,
    LOCATION = N'https://009storage.blob.core.windows.net/',
    CREDENTIAL = [MyBlobStorageCredential2]
    );


GO

