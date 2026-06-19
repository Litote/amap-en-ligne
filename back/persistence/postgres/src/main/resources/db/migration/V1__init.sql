-- Consolidated baseline schema (squashed from former V1..V47).
-- Generated via pg_dump --schema-only of the fully-migrated dev DB; do not edit by hand.
-- Add further changes as new V2+ migrations.

--
-- PostgreSQL database dump
--


-- Dumped from database version 16.13 (Debian 16.13-1.pgdg13+1)
-- Dumped by pg_dump version 16.13 (Debian 16.13-1.pgdg13+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--



SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: account_deletion_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.account_deletion_log (
    id text NOT NULL,
    deleted_sub_hash text NOT NULL,
    deleted_role text NOT NULL,
    deleted_at bigint NOT NULL,
    actor_owner_id text NOT NULL
);


--
-- Name: activation_token; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.activation_token (
    token text NOT NULL,
    request_id text,
    admin_email text NOT NULL,
    created_at bigint NOT NULL,
    expires_at bigint NOT NULL,
    email_sent boolean DEFAULT false NOT NULL,
    organization_id text,
    activated_at bigint,
    kind text DEFAULT 'ORGANIZATION_ADMIN'::text NOT NULL,
    owner_invitation_id text,
    member_invitation_id text,
    invalidated_at bigint,
    producer_request_id text,
    producer_account_id text
);


--
-- Name: attendance_email_request; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.attendance_email_request (
    attendance_email_request_id text NOT NULL,
    organization_id text NOT NULL,
    delivery_id text NOT NULL,
    recipient_email text NOT NULL,
    requested_at bigint NOT NULL,
    sent_at bigint
);


--
-- Name: basket_exchange; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.basket_exchange (
    basket_exchange_id text NOT NULL,
    organization_id text NOT NULL,
    delivery_id text NOT NULL,
    contract_id text NOT NULL,
    offering_member_id text NOT NULL,
    motive text,
    status text NOT NULL,
    created_at bigint NOT NULL,
    decided_at bigint,
    accepted_request_id text,
    requests_json text DEFAULT '[]'::text NOT NULL
);


--
-- Name: changes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.changes (
    cursor text NOT NULL,
    entity_type text NOT NULL,
    scope_key text NOT NULL,
    entity_id text NOT NULL,
    op text NOT NULL,
    payload jsonb,
    produced_at bigint NOT NULL
);


--
-- Name: contract; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contract (
    contract_id text NOT NULL,
    organization_id text NOT NULL,
    min_delivery_date text NOT NULL,
    max_delivery_date text NOT NULL,
    delivery_count integer NOT NULL,
    season_year integer NOT NULL,
    coordinators jsonb DEFAULT '[]'::jsonb NOT NULL,
    members jsonb DEFAULT '[]'::jsonb NOT NULL,
    created_instant bigint DEFAULT 0 NOT NULL,
    last_updated_instant bigint DEFAULT 0 NOT NULL,
    producer_account_id text DEFAULT ''::text NOT NULL,
    product_prices_json text DEFAULT '[]'::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    status text DEFAULT 'IN_PREPARATION'::text NOT NULL,
    delivery_template_id text
);


--
-- Name: delivery_template; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.delivery_template (
    delivery_template_id text NOT NULL,
    organization_id text NOT NULL,
    name text NOT NULL,
    standard_start_time text NOT NULL,
    standard_end_time text NOT NULL,
    early_slot text,
    desired_volunteer_count integer DEFAULT 0 NOT NULL,
    volunteer_arrival_time text
);


--
-- Name: device_token; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.device_token (
    device_token_id text NOT NULL,
    recipient_scope text NOT NULL,
    platform text NOT NULL,
    token text NOT NULL,
    created_at bigint NOT NULL,
    last_seen_at bigint NOT NULL
);


--
-- Name: error_report; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.error_report (
    error_report_id text NOT NULL,
    error_message text NOT NULL,
    reported_at bigint NOT NULL
);


--
-- Name: member; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.member (
    member_id text NOT NULL,
    organization_id text NOT NULL,
    active_status boolean DEFAULT true NOT NULL,
    contracts jsonb DEFAULT '[]'::jsonb NOT NULL,
    notifications jsonb DEFAULT '[]'::jsonb NOT NULL,
    registrations jsonb DEFAULT '[]'::jsonb NOT NULL,
    member_settings jsonb DEFAULT '{}'::jsonb NOT NULL,
    member_preferences jsonb DEFAULT '{}'::jsonb NOT NULL,
    user_preferences jsonb DEFAULT '{}'::jsonb NOT NULL,
    user_settings jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_instant bigint DEFAULT 0 NOT NULL,
    last_updated_instant bigint DEFAULT 0 NOT NULL,
    roles text[] DEFAULT '{VOLUNTEER}'::text[] NOT NULL,
    first_name text,
    last_name text,
    email text,
    phone text,
    account_status text
);


--
-- Name: member_invitation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.member_invitation (
    invitation_id text NOT NULL,
    organization_id text NOT NULL,
    email text NOT NULL,
    first_name text NOT NULL,
    last_name text NOT NULL,
    roles text NOT NULL,
    created_at bigint NOT NULL,
    expires_at bigint NOT NULL,
    activated_at bigint,
    status text DEFAULT 'PENDING_ACTIVATION'::text NOT NULL,
    resend_requested_at bigint,
    custom_email_subject text,
    custom_email_body text
);


--
-- Name: member_join_request; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.member_join_request (
    request_id text NOT NULL,
    organization_id text NOT NULL,
    email text NOT NULL,
    first_name text NOT NULL,
    last_name text NOT NULL,
    status text DEFAULT 'PENDING'::text NOT NULL,
    submitted_at bigint NOT NULL,
    reviewed_at bigint,
    review_comment text
);


--
-- Name: notification; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notification (
    notification_id text NOT NULL,
    recipient_scope text NOT NULL,
    notification_type text NOT NULL,
    category text NOT NULL,
    title text NOT NULL,
    body text NOT NULL,
    deep_link text,
    related_entity_id text,
    created_at bigint NOT NULL,
    read_at bigint
);


--
-- Name: organization; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organization (
    organization_id text NOT NULL,
    name text NOT NULL,
    contact_email text NOT NULL,
    active_status boolean DEFAULT true NOT NULL,
    timezone text DEFAULT 'Europe/Paris'::text NOT NULL,
    default_language text DEFAULT 'fr'::text NOT NULL,
    website text,
    created_instant bigint DEFAULT 0 NOT NULL,
    last_updated_instant bigint DEFAULT 0 NOT NULL,
    deliveries jsonb DEFAULT '[]'::jsonb NOT NULL,
    default_delivery_template_id text,
    notification_overrides jsonb DEFAULT '{}'::jsonb NOT NULL,
    item_types jsonb DEFAULT '[]'::jsonb NOT NULL
);


--
-- Name: organization_producer; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organization_producer (
    organization_id text NOT NULL,
    producer_account_id text NOT NULL,
    association_instant bigint NOT NULL,
    status text DEFAULT 'ACTIVE'::text NOT NULL
);


--
-- Name: organization_product; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organization_product (
    organization_id text NOT NULL,
    producer_account_id text NOT NULL,
    product_type_id text NOT NULL,
    name text NOT NULL,
    supported_basket_sizes text DEFAULT '[]'::text NOT NULL,
    description text
);


--
-- Name: organization_request; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organization_request (
    request_id text NOT NULL,
    organization_name text NOT NULL,
    timezone text NOT NULL,
    default_language text NOT NULL,
    admin_first_name text NOT NULL,
    admin_last_name text NOT NULL,
    admin_email text NOT NULL,
    status text DEFAULT 'PENDING_VALIDATION'::text NOT NULL,
    submitted_at bigint NOT NULL,
    reviewed_at bigint,
    review_comment text,
    organization_type text DEFAULT 'AMAP'::text NOT NULL,
    submitter_comment text,
    organization_id text,
    resend_requested_at bigint
);


--
-- Name: owner; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.owner (
    owner_id text NOT NULL,
    first_name text NOT NULL,
    last_name text NOT NULL,
    email text NOT NULL,
    phone text,
    account_status text DEFAULT 'ACTIVE'::text NOT NULL,
    registered_at bigint NOT NULL,
    updated_at bigint NOT NULL,
    user_preferences jsonb DEFAULT '{"last_updated_instant": "1970-01-01T00:00:00Z", "sms_notifications_enabled": false, "push_notifications_enabled": false, "email_notifications_enabled": true}'::jsonb NOT NULL
);


--
-- Name: owner_invitation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.owner_invitation (
    invitation_id text NOT NULL,
    first_name text NOT NULL,
    last_name text NOT NULL,
    email text NOT NULL,
    status text DEFAULT 'PENDING_ACTIVATION'::text NOT NULL,
    submitted_at bigint NOT NULL,
    activated_at bigint,
    resend_requested_at bigint
);


--
-- Name: producer; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.producer (
    producer_id character varying NOT NULL,
    producer_account_id character varying NOT NULL,
    role character varying NOT NULL,
    association_instant bigint NOT NULL,
    status character varying NOT NULL,
    producer_preferences text NOT NULL,
    user_preferences text NOT NULL,
    user_settings text NOT NULL
);


--
-- Name: producer_account; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.producer_account (
    producer_account_id text NOT NULL,
    name text NOT NULL,
    contact_email text,
    address text,
    website text,
    active_status boolean DEFAULT true NOT NULL,
    created_instant bigint NOT NULL,
    last_updated_instant bigint NOT NULL,
    user_preferences jsonb DEFAULT '{"last_updated_instant": "1970-01-01T00:00:00Z", "sms_notifications_enabled": false, "push_notifications_enabled": false, "email_notifications_enabled": true}'::jsonb NOT NULL,
    management_mode text DEFAULT 'ACCOUNT_BACKED'::text NOT NULL,
    linked_producer_account_id text,
    linked_producer_account_name text
);


--
-- Name: producer_request; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.producer_request (
    request_id text NOT NULL,
    producer_name text NOT NULL,
    admin_first_name text NOT NULL,
    admin_last_name text NOT NULL,
    admin_email text NOT NULL,
    status text DEFAULT 'PENDING_VALIDATION'::text NOT NULL,
    submitted_at bigint NOT NULL,
    reviewed_at bigint,
    review_comment text,
    submitter_comment text,
    producer_account_id text,
    resend_requested_at bigint
);


--
-- Name: product_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_type (
    producer_account_id text NOT NULL,
    product_type_id text NOT NULL,
    name text NOT NULL,
    description text,
    supported_basket_sizes jsonb NOT NULL
);


--
-- Name: server; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.server (
    server_id text NOT NULL,
    name text NOT NULL,
    url text NOT NULL
);


--
-- Name: account_deletion_log account_deletion_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_deletion_log
    ADD CONSTRAINT account_deletion_log_pkey PRIMARY KEY (id);


--
-- Name: activation_token activation_token_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activation_token
    ADD CONSTRAINT activation_token_pkey PRIMARY KEY (token);


--
-- Name: attendance_email_request attendance_email_request_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendance_email_request
    ADD CONSTRAINT attendance_email_request_pkey PRIMARY KEY (attendance_email_request_id);


--
-- Name: basket_exchange basket_exchange_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.basket_exchange
    ADD CONSTRAINT basket_exchange_pkey PRIMARY KEY (basket_exchange_id);


--
-- Name: changes changes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.changes
    ADD CONSTRAINT changes_pkey PRIMARY KEY (scope_key, entity_type, entity_id);


--
-- Name: contract contract_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contract
    ADD CONSTRAINT contract_pkey PRIMARY KEY (contract_id);


--
-- Name: delivery_template delivery_template_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delivery_template
    ADD CONSTRAINT delivery_template_pkey PRIMARY KEY (delivery_template_id);


--
-- Name: device_token device_token_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.device_token
    ADD CONSTRAINT device_token_pkey PRIMARY KEY (device_token_id);


--
-- Name: error_report error_report_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.error_report
    ADD CONSTRAINT error_report_pkey PRIMARY KEY (error_report_id);


--
-- Name: member_invitation member_invitation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member_invitation
    ADD CONSTRAINT member_invitation_pkey PRIMARY KEY (invitation_id);


--
-- Name: member_join_request member_join_request_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member_join_request
    ADD CONSTRAINT member_join_request_pkey PRIMARY KEY (request_id);


--
-- Name: member member_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member
    ADD CONSTRAINT member_pkey PRIMARY KEY (member_id);


--
-- Name: notification notification_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification
    ADD CONSTRAINT notification_pkey PRIMARY KEY (notification_id);


--
-- Name: organization organization_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization
    ADD CONSTRAINT organization_pkey PRIMARY KEY (organization_id);


--
-- Name: organization_producer organization_producer_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_producer
    ADD CONSTRAINT organization_producer_pkey PRIMARY KEY (organization_id, producer_account_id);


--
-- Name: organization_product organization_product_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_product
    ADD CONSTRAINT organization_product_pkey PRIMARY KEY (organization_id, producer_account_id, product_type_id);


--
-- Name: organization_request organization_request_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_request
    ADD CONSTRAINT organization_request_pkey PRIMARY KEY (request_id);


--
-- Name: owner owner_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.owner
    ADD CONSTRAINT owner_email_key UNIQUE (email);


--
-- Name: owner_invitation owner_invitation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.owner_invitation
    ADD CONSTRAINT owner_invitation_pkey PRIMARY KEY (invitation_id);


--
-- Name: owner owner_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.owner
    ADD CONSTRAINT owner_pkey PRIMARY KEY (owner_id);


--
-- Name: producer_account producer_account_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.producer_account
    ADD CONSTRAINT producer_account_pkey PRIMARY KEY (producer_account_id);


--
-- Name: producer producer_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.producer
    ADD CONSTRAINT producer_pkey PRIMARY KEY (producer_id);


--
-- Name: producer_request producer_request_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.producer_request
    ADD CONSTRAINT producer_request_pkey PRIMARY KEY (request_id);


--
-- Name: product_type product_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_type
    ADD CONSTRAINT product_type_pkey PRIMARY KEY (producer_account_id, product_type_id);


--
-- Name: server server_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.server
    ADD CONSTRAINT server_pkey PRIMARY KEY (server_id);


--
-- Name: attendance_email_request_organization_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX attendance_email_request_organization_id_idx ON public.attendance_email_request USING btree (organization_id);


--
-- Name: basket_exchange_organization_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX basket_exchange_organization_id_idx ON public.basket_exchange USING btree (organization_id);


--
-- Name: changes_by_scope_cursor; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX changes_by_scope_cursor ON public.changes USING btree (scope_key, cursor);


--
-- Name: device_token_recipient_scope_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX device_token_recipient_scope_idx ON public.device_token USING btree (recipient_scope);


--
-- Name: device_token_scope_token_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX device_token_scope_token_idx ON public.device_token USING btree (recipient_scope, token);


--
-- Name: idx_account_deletion_log_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_account_deletion_log_deleted_at ON public.account_deletion_log USING btree (deleted_at);


--
-- Name: idx_contract_organization; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contract_organization ON public.contract USING btree (organization_id);


--
-- Name: idx_member_organization; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_member_organization ON public.member USING btree (organization_id);


--
-- Name: member_invitation_unique_pending_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX member_invitation_unique_pending_email ON public.member_invitation USING btree (email) WHERE (status = 'PENDING_ACTIVATION'::text);


--
-- Name: member_join_request_pending_email_organization_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX member_join_request_pending_email_organization_idx ON public.member_join_request USING btree (email, organization_id) WHERE (status = 'PENDING'::text);


--
-- Name: notification_recipient_scope_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notification_recipient_scope_idx ON public.notification USING btree (recipient_scope);


--
-- Name: producer_account_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX producer_account_id_idx ON public.producer USING btree (producer_account_id);


--
-- Name: producer_account_linked_producer_account_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX producer_account_linked_producer_account_id_idx ON public.producer_account USING btree (linked_producer_account_id);


--
-- Name: activation_token activation_token_member_invitation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activation_token
    ADD CONSTRAINT activation_token_member_invitation_id_fkey FOREIGN KEY (member_invitation_id) REFERENCES public.member_invitation(invitation_id);


--
-- Name: activation_token activation_token_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activation_token
    ADD CONSTRAINT activation_token_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organization(organization_id);


--
-- Name: activation_token activation_token_owner_invitation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activation_token
    ADD CONSTRAINT activation_token_owner_invitation_id_fkey FOREIGN KEY (owner_invitation_id) REFERENCES public.owner_invitation(invitation_id);


--
-- Name: activation_token activation_token_producer_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activation_token
    ADD CONSTRAINT activation_token_producer_account_id_fkey FOREIGN KEY (producer_account_id) REFERENCES public.producer_account(producer_account_id);


--
-- Name: activation_token activation_token_producer_request_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activation_token
    ADD CONSTRAINT activation_token_producer_request_id_fkey FOREIGN KEY (producer_request_id) REFERENCES public.producer_request(request_id);


--
-- Name: activation_token activation_token_request_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activation_token
    ADD CONSTRAINT activation_token_request_id_fkey FOREIGN KEY (request_id) REFERENCES public.organization_request(request_id);


--
-- Name: basket_exchange basket_exchange_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.basket_exchange
    ADD CONSTRAINT basket_exchange_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organization(organization_id);


--
-- Name: contract contract_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contract
    ADD CONSTRAINT contract_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organization(organization_id);


--
-- Name: member_invitation member_invitation_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member_invitation
    ADD CONSTRAINT member_invitation_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organization(organization_id);


--
-- Name: member_join_request member_join_request_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member_join_request
    ADD CONSTRAINT member_join_request_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organization(organization_id);


--
-- Name: member member_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member
    ADD CONSTRAINT member_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organization(organization_id);


--
-- Name: organization_producer organization_producer_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_producer
    ADD CONSTRAINT organization_producer_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organization(organization_id);


--
-- Name: organization_producer organization_producer_producer_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_producer
    ADD CONSTRAINT organization_producer_producer_account_id_fkey FOREIGN KEY (producer_account_id) REFERENCES public.producer_account(producer_account_id);


--
-- Name: organization_product organization_product_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_product
    ADD CONSTRAINT organization_product_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organization(organization_id) ON DELETE CASCADE;


--
-- Name: organization_product organization_product_producer_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_product
    ADD CONSTRAINT organization_product_producer_account_id_fkey FOREIGN KEY (producer_account_id) REFERENCES public.producer_account(producer_account_id);


--
-- Name: producer_account producer_account_linked_producer_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.producer_account
    ADD CONSTRAINT producer_account_linked_producer_account_id_fkey FOREIGN KEY (linked_producer_account_id) REFERENCES public.producer_account(producer_account_id);


--
-- PostgreSQL database dump complete
--


