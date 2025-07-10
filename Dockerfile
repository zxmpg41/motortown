###########################################################
# Dockerfile that builds a MotorTown Dedicated Server
###########################################################

# BUILD STAGE

FROM cm2network/steamcmd:root-bookworm as build_stage

LABEL maintainer="joedwards32@gmail.com"
LABEL maintainer="mmenistr@gmail.com"

ENV STEAMAPPID 2223650
ENV STEAMAPP motortown
ENV STEAMAPPDIR "${HOMEDIR}/${STEAMAPP}-dedicated"
ENV STEAMAPPVALIDATE 0

COPY etc/entry.sh "${HOMEDIR}/entry.sh"
COPY etc/DedicatedServerConfig_Sample.json "/etc/DedicatedServerConfig_Sample.json"
COPY etc/pre.sh "/etc/pre.sh"
COPY etc/post.sh "/etc/post.sh"

RUN set -x \
	# Install, update & upgrade packages
	&& apt-get update \
	&& apt-get install -y --no-install-recommends --no-install-suggests \
		wget \
		ca-certificates \
		lib32z1 \
                simpleproxy \
                libicu-dev \
                unzip \
		jq \
	&& mkdir -p "${STEAMAPPDIR}" \
	# Add entry script
	&& chmod +x "${HOMEDIR}/entry.sh" \
	&& chown -R "${USER}:${USER}" "${HOMEDIR}/entry.sh" "${STEAMAPPDIR}" \
	# Clean up
        && apt-get clean \
        && find /var/lib/apt/lists/ -type f -delete

# BASE

FROM build_stage AS bookworm-base

ENV SERVER_HOSTNAME="motortown private server" \
    SERVER_MESSAGE="Welcome!\nHave fun!" \
    SERVER_PASSWORD="" \
    MAX_PLAYERS=10 \
    MAX_PLAYER_VEHICLES=5 \
    ALLOW_COMPANY_VEHCILES=false \
    ALLOW_COMPANY_AI=true \
    MAX_HOUSING_RENTAL_PLOTS=1 \
    MAX_HOUSING_RENTAL_DAYS=7 \    
    HOUSING_RENTAL_PRICE_RATIO=0.1 \
    ALLOW_MODDED_VEHICLES=false \
    NPC_VEHICLE_DENSITY=1.0 \
    NPC_POLICE_DENSITY=1.0 \
    ENABLE_WEB_API=false \
    WEB_API_PASSWORD="pa$$w0rd" \
    WEB_API_PORT=8080

# Set permissions on STEAMAPPDIR
#   Permissions may need to be reset if persistent volume mounted
RUN set -x \
        && chown -R "${USER}:${USER}" "${STEAMAPPDIR}" \
        && chmod 0777 "${STEAMAPPDIR}"

# Switch to user
USER ${USER}

WORKDIR ${HOMEDIR}

CMD ["bash", "entry.sh"]

# Expose ports
EXPOSE 7777/tcp \
	27015/tcp \
	27015/udp \
    7777/udp