#!/bin/bash

# Debug

## Steamcmd debugging
if [[ $DEBUG -eq 1 ]] || [[ $DEBUG -eq 3 ]]; then
    STEAMCMD_SPEW="+set_spew_level 4 4"
fi

# Create App Dir
mkdir -p "${STEAMAPPDIR}" || true

# Download Updates
if [[ "$STEAMAPPVALIDATE" -eq 1 ]]; then
    VALIDATE="validate"
else
    VALIDATE=""
fi

## SteamCMD can fail to download
## Retry logic
MAX_ATTEMPTS=3
attempt=0
while [[ $steamcmd_rc != 0 ]] && [[ $attempt -lt $MAX_ATTEMPTS ]]; do
    ((attempt+=1))
    if [[ $attempt -gt 1 ]]; then
        echo "Retrying SteamCMD, attempt ${attempt}"
        # Stale appmanifest data can lead for HTTP 401 errors when requesting old
        # files from SteamPipe CDN
        echo "Removing steamapps (appmanifest data)..."
        rm -rf "${STEAMAPPDIR}/steamapps"
    fi
    eval bash "${STEAMCMDDIR}/steamcmd.sh" "${STEAMCMD_SPEW}"\
                                +force_install_dir "${STEAMAPPDIR}" \
                                +@bClientTryRequestManifestWithoutCode 1 \
				+login anonymous \
				+app_update "${STEAMAPPID}" -beta "test2" -betapassword "motortowndeti" "${VALIDATE}"\
				+quit 
    steamcmd_rc=$?
done

## Exit if steamcmd fails
if [[ $steamcmd_rc != 0 ]]; then
    exit $steamcmd_rc
fi

# steamclient.so fix
mkdir -p ~/.steam/sdk64
ln -sfT ${STEAMCMDDIR}/linux64/steamclient.so ~/.steam/sdk64/steamclient.so

# Install DedicatedServerConfig_Sample.json
mkdir -p $STEAMAPPDIR/game/motortown/cfg
cp /etc/DedicatedServerConfig_Sample.json "${STEAMAPPDIR}"/game/motortown/cfg/DedicatedServerConfig_Sample.json

# Install hooks if they don't already exist
if [[ ! -f "${STEAMAPPDIR}/pre.sh" ]] ; then
    cp /etc/pre.sh "${STEAMAPPDIR}/pre.sh"
fi
if [[ ! -f "${STEAMAPPDIR}/post.sh" ]] ; then
    cp /etc/post.sh "${STEAMAPPDIR}/post.sh"
fi

# Download and extract custom config bundle
if [[ ! -z $MT_CFG_URL ]]; then
    echo "Downloading config pack from ${MT_CFG_URL}"

    TEMP_DIR=$(mktemp -d)
    TEMP_FILE="${TEMP_DIR}/$(basename ${MT_CFG_URL})"
    wget -qO "${TEMP_FILE}" "${MT_CFG_URL}"

    case "${TEMP_FILE}" in
        *.zip)
            echo "Extracting ZIP file..."
            unzip -q "${TEMP_FILE}" -d "${STEAMAPPDIR}"
            ;;
        *.tar.gz | *.tgz)
            echo "Extracting TAR.GZ or TGZ file..."
            tar xvzf "${TEMP_FILE}" -C "${STEAMAPPDIR}"
            ;;
        *.tar)
            echo "Extracting TAR file..."
            tar xvf "${TEMP_FILE}" -C "${STEAMAPPDIR}"
            ;;
        *)
            echo "Unsupported file type"
            rm -rf "${TEMP_DIR}"
            exit 1
            ;;
    esac

    rm -rf "${TEMP_DIR}"
fi

# Rewrite Config Files

sed -i -e "s/{{SERVER_HOSTNAME}}/${SERVER_HOSTNAME}/g" \
       -e "s/{{SERVER_MESSAGE}}/${SERVER_MESSAGE}/g" \
       -e "s/{{SERVER_PASSWORD}}/${SERVER_PASSWORD}/g" \
       -e "s/{{MAX_PLAYERS}}/${MAX_PLAYERS}/g" \
       -e "s/{{MAX_PLAYER_VEHICLES}}/${MAX_PLAYER_VEHICLES}/g" \
       -e "s/{{ALLOW_COMPANY_VEHCILES}}/${ALLOW_COMPANY_VEHCILES}/g" \
       -e "s/{{ALLOW_COMPANY_AI}}/${ALLOW_COMPANY_AI}/g" \
       -e "s/{{MAX_HOUSING_RENTAL_PLOTS}}/${MAX_HOUSING_RENTAL_PLOTS}/g" \
       -e "s/{{MAX_HOUSING_RENTAL_DAYS}}/${MAX_HOUSING_RENTAL_DAYS}/g" \
       -e "s/{{HOUSING_RENTAL_PRICE_RATIO}}/${HOUSING_RENTAL_PRICE_RATIO}/g" \
       -e "s/{{ALLOW_MODDED_VEHICLES}}/${ALLOW_MODDED_VEHICLES}/g" \
       -e "s/{{NPC_VEHICLE_DENSITY}}/${NPC_VEHICLE_DENSITY}/g" \
       -e "s/{{NPC_POLICE_DENSITY}}/${NPC_POLICE_DENSITY}/g" \
       -e "s/{{ENABLE_WEB_API}}/${ENABLE_WEB_API}/g" \
       -e "s/{{WEB_API_PASSWORD}}/${WEB_API_PASSWORD}/g" \
       -e "s/{{WEB_API_PORT}}/${WEB_API_PORT}/g" \
       "${STEAMAPPDIR}"/game/motortown/cfg/DedicatedServerConfig_Sample.json

# Switch to server directory
cd "${STEAMAPPDIR}/game/bin/linuxsteamrt64"

# Pre Hook
source "${STEAMAPPDIR}/pre.sh"

# Start Server

echo "Starting MotorTown Dedicated Server - ${SERVER_HOSTNAME}"
eval bash ${STEAMCMDDIR}/steamcmd.sh" "${STEAMCMD_SPEW}" +app_run "${STEAMAPPID}"

# Post Hook
source "${STEAMAPPDIR}/post.sh"