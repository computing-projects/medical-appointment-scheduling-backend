-- Tipos enumerados
CREATE TYPE medsim.user_type_enum AS ENUM ('admin', 'doctor', 'secretary', 'client');
CREATE TYPE medsim.clinic_role AS ENUM ('admin', 'doctor', 'secretary');
CREATE TYPE medsim.specialty_type AS ENUM (
    'Cardiology', 'Dermatology', 'Endocrinology', 'Gastroenterology', 
    'Neurology', 'Orthopedics', 'Pediatrics', 'Psychiatry', 'General'
);
CREATE TYPE medsim.health_plan_type AS ENUM ('SUS', 'Unimed', 'Bradesco', 'Amil', 'Other');
CREATE TYPE medsim.appointment_type_enum AS ENUM ('in_person', 'online');
CREATE TYPE medsim.appointment_status_enum AS ENUM ('scheduled', 'completed', 'canceled', 'no_show');
CREATE TYPE medsim.waitlist_status_enum AS ENUM ('pending', 'confirmed', 'canceled');
CREATE TYPE medsim.notification_type_enum AS ENUM ('email', 'whatsapp');
CREATE TYPE medsim.notification_status_enum AS ENUM ('pending', 'sent', 'failed');
CREATE TYPE medsim.weekday_enum AS ENUM ('monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday');
CREATE TYPE medsim.chat_status_enum AS ENUM ('sent', 'delivered', 'read');

-- Tabela de Clinicas
CREATE TABLE medsim.clinics (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL CHECK (LENGTH(name) > 3),
    address TEXT NOT NULL,
    cnpj VARCHAR(20) UNIQUE NOT NULL CHECK (cnpj ~ '^\d{2}\.?\d{3}\.?\d{3}\/?\d{4}-?\d{2}$'),
    email VARCHAR(255) UNIQUE NOT NULL CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    phone VARCHAR(20) NOT NULL CHECK (phone ~ '^\+?[0-9\s-]+$'),
    website VARCHAR(255) CHECK (website ~* '^(https?:\/\/)?([\w\d-]+\.)+[\w]{2,}(\/[\w\d-./?%&=]*)?$'),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ DEFAULT NULL
);

-- Tabela de Usuarios
CREATE TABLE medsim.users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL CHECK (LENGTH(name) > 3),
    email VARCHAR(255) UNIQUE NOT NULL CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    password_hash TEXT NOT NULL,
    phone VARCHAR(20) CHECK (phone ~ '^\+?[0-9\s-]+$'),
    user_type medsim.user_type_enum NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ DEFAULT NULL
);

-- Tabela Relacional de Clinicas e Usuarios (Excluindo clientes)
CREATE TABLE medsim.clinic_users (
    id SERIAL PRIMARY KEY,
    clinic_id INT NOT NULL REFERENCES medsim.clinics(id) ON DELETE CASCADE,
    user_id INT NOT NULL REFERENCES medsim.users(id) ON DELETE CASCADE,
    role medsim.clinic_role NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (clinic_id, user_id)
);

-- Tabela de Medicos
CREATE TABLE medsim.doctors (
    id SERIAL PRIMARY KEY,
    user_id INT UNIQUE NOT NULL REFERENCES medsim.users(id) ON DELETE CASCADE,
    crm VARCHAR(20) UNIQUE NOT NULL CHECK (crm ~ '^CRM\/[A-Z]{2} [0-9]{6}$'),
    specialty medsim.specialty_type NOT NULL DEFAULT 'General',
    appointment_duration_min INT NOT NULL CHECK (appointment_duration_min BETWEEN 10 AND 120),
);

-- Tabela de Planos aceitos por Medicos
CREATE TABLE medsim.doctor_health_plans (
    doctor_id INT NOT NULL REFERENCES medsim.doctors(id) ON DELETE CASCADE,
    health_plan medsim.health_plan_type NOT NULL,
    PRIMARY KEY (doctor_id, health_plan)
);

-- Tabela de Pacientes (Clientes)
CREATE TABLE medsim.clients (
    id SERIAL PRIMARY KEY,
    user_id INT UNIQUE NOT NULL REFERENCES medsim.users(id) ON DELETE CASCADE,
    rg VARCHAR(20) UNIQUE NOT NULL CHECK (rg ~ '^[0-9.-]+$'),
    cpf VARCHAR(14) UNIQUE NOT NULL CHECK (cpf ~ '^[0-9]{3}\.?[0-9]{3}\.?[0-9]{3}-?[0-9Xx]{2}$'),
    health_plan medsim.health_plan_type DEFAULT 'Other',
    health_history TEXT DEFAULT NULL,
    date_of_birth DATE NOT NULL,
);

-- Tabela de Agendamentos
CREATE TABLE medsim.appointments (
    id SERIAL PRIMARY KEY,
    clinic_id INT REFERENCES medsim.clinics(id) ON DELETE SET NULL,
    doctor_id INT REFERENCES medsim.doctors(id) ON DELETE SET NULL,
    client_id INT REFERENCES medsim.clients(id) ON DELETE SET NULL,
    appointment_datetime TIMESTAMPTZ NOT NULL,
    appointment_type medsim.appointment_type_enum NOT NULL, 
    status medsim.appointment_status_enum NOT NULL,
    video_call_link TEXT CHECK (appointment_type = 'online' OR video_call_link IS NULL),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT valid_video_link CHECK (
        (video_call_link IS NULL) 
        OR (video_call_link ~* '^(https?:\/\/)?([\w\d-]+\.)+[\w]{2,}(\/[\w\d-./?%&=]*)?$')
    )
);

-- Lista de Espera
CREATE TABLE medsim.waitlist (
    id SERIAL PRIMARY KEY,
    appointment_id INT NOT NULL REFERENCES medsim.appointments(id) ON DELETE CASCADE,
    interested_client_id INT NOT NULL REFERENCES medsim.clients(id) ON DELETE CASCADE,
    status medsim.waitlist_status_enum NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Notificacoes
CREATE TABLE medsim.notifications (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES medsim.users(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    type medsim.notification_type_enum NOT NULL,
    status medsim.notification_status_enum NOT NULL DEFAULT 'pending',
    sent BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Avaliacoes
CREATE TABLE medsim.reviews (
    id SERIAL PRIMARY KEY,
    appointment_id INT UNIQUE NOT NULL REFERENCES medsim.appointments(id) ON DELETE SET NULL,
    rating INT CHECK (rating BETWEEN 1 AND 5) NOT NULL,
    comment VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
);

-- Horarios dos Medicos
CREATE TABLE medsim.schedules (
    id SERIAL PRIMARY KEY,
    doctor_id INT NOT NULL REFERENCES medsim.doctors(id) ON DELETE CASCADE,
    weekday medsim.weekday_enum NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE (doctor_id, weekday, start_time)
);

-- Chat
CREATE TABLE medsim.chat (
    id SERIAL PRIMARY KEY,
    sender_id INT NOT NULL REFERENCES medsim.users(id) ON DELETE CASCADE,
    receiver_id INT NOT NULL REFERENCES medsim.users(id) ON DELETE CASCADE,
    message VARCHAR(1000),
    status medsim.chat_status_enum NOT NULL DEFAULT 'sent',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    expires_at TIMESTAMPTZ DEFAULT NULL,
    UNIQUE (sender_id, receiver_id, created_at)
);

-- Index
CREATE INDEX idx_clinics_cnpj ON medsim.clinics (cnpj);

CREATE UNIQUE INDEX idx_doctors_crm ON medsim.doctors (crm);
CREATE INDEX idx_doctors_specialty ON medsim.doctors (specialty);

CREATE UNIQUE INDEX idx_clients_cpf ON medsim.clients (cpf);
CREATE UNIQUE INDEX idx_clients_rg ON medsim.clients (rg);

CREATE INDEX idx_appointments_appointment_datetime ON medsim.appointments(appointment_datetime);

CREATE INDEX idx_waitlist_interested_client_id ON medsim.waitlist(interested_client_id);

CREATE INDEX idx_notifications_user_id ON medsim.notifications(user_id);

CREATE INDEX idx_schedules_doctor_id ON medsim.schedules(doctor_id);
CREATE INDEX idx_schedules_weekday ON medsim.schedules(weekday);

CREATE INDEX idx_chat_sender_receiver ON medsim.chat (sender_id, receiver_id);
CREATE INDEX idx_chat_receiver_sender ON medsim.chat (receiver_id, sender_id);
CREATE INDEX idx_chat_status ON medsim.chat (status);