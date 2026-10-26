ARG WORKER_DLL_IMAGE=dockerhubaneo/armonik-dynamic-dotnet-worker:0.23.0

FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY . .


WORKDIR "/src/End2EndTests/ArmoniK.EndToEndTests.Worker"

RUN dotnet publish -a "${TARGETARCH}" --self-contained -c Release -f net10.0 .

FROM ${WORKER_DLL_IMAGE} AS final

COPY --from=build /src/End2EndTests/publish/ArmoniK.EndToEndTests.Worker/1.0.0-100 /guest
