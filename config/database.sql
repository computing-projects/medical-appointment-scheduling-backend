-- Tabela de Clinicas
CREATE TABLE medsim.clinics (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    address TEXT NOT NULL,
    cnpj VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20) NOT NULL,
    website VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de Usuarios
CREATE TABLE medsim.users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    phone VARCHAR(20),
    user_type VARCHAR(50) CHECK (user_type IN ('admin', 'doctor', 'secretary', 'client')) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela Relacional de Clinicas e Usuarios (Excluindo clientes)
CREATE TABLE medsim.clinic_users (
    id SERIAL PRIMARY KEY,
    clinic_id INT NOT NULL REFERENCES medsim.clinics(id) ON DELETE CASCADE,
    user_id INT NOT NULL REFERENCES medsim.users(id) ON DELETE CASCADE,
    role VARCHAR(50) CHECK (role IN ('admin', 'doctor', 'secretary')) NOT NULL,
    UNIQUE (clinic_id, user_id)
);

-- Tabela de Medicos
CREATE TABLE medsim.doctors (
    id SERIAL PRIMARY KEY,
    user_id INT UNIQUE NOT NULL REFERENCES medsim.users(id) ON DELETE CASCADE,
    crm VARCHAR(20) UNIQUE NOT NULL,
    specialty VARCHAR(255) NOT NULL,
    accepted_health_plans TEXT,
    appointment_duration_min INT NOT NULL
);

-- Tabela de Pacientes (Clientes)
CREATE TABLE medsim.clients (
    id SERIAL PRIMARY KEY,
    user_id INT UNIQUE NOT NULL REFERENCES medsim.users(id) ON DELETE CASCADE,
    rg VARCHAR(20) UNIQUE NOT NULL,
    cpf VARCHAR(14) UNIQUE NOT NULL,
    health_plan VARCHAR(255),
    health_history TEXT,
    date_of_birth DATE NOT NULL
);

-- Tabela de Agendamentos
CREATE TABLE medsim.appointments (
    id SERIAL PRIMARY KEY,
    clinic_id INT NOT NULL REFERENCES medsim.clinics(id) ON DELETE CASCADE,
    doctor_id INT NOT NULL REFERENCES medsim.doctors(id) ON DELETE CASCADE,
    client_id INT NOT NULL REFERENCES medsim.clients(id) ON DELETE CASCADE,
    appointment_datetime TIMESTAMP NOT NULL,
    appointment_type VARCHAR(20) CHECK (appointment_type IN ('in_person', 'online')) NOT NULL,
    status VARCHAR(50) CHECK (status IN ('scheduled', 'completed', 'canceled', 'no_show')) NOT NULL,
    video_call_link TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Lista de Espera
CREATE TABLE medsim.waitlist (
    id SERIAL PRIMARY KEY,
    appointment_id INT NOT NULL REFERENCES medsim.appointments(id) ON DELETE CASCADE,
    interested_client_id INT NOT NULL REFERENCES medsim.clients(id) ON DELETE CASCADE,
    status VARCHAR(50) CHECK (status IN ('pending', 'confirmed', 'canceled')) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Notificacoes
CREATE TABLE medsim.notifications (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES medsim.users(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    type VARCHAR(50) CHECK (type IN ('email', 'whatsapp')) NOT NULL,
    sent BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Avaliacoes
CREATE TABLE medsim.reviews (
    id SERIAL PRIMARY KEY,
    appointment_id INT UNIQUE NOT NULL REFERENCES medsim.appointments(id) ON DELETE CASCADE,
    rating INT CHECK (rating BETWEEN 1 AND 5) NOT NULL,
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Horarios dos Medicos
CREATE TABLE medsim.schedules (
    id SERIAL PRIMARY KEY,
    doctor_id INT NOT NULL REFERENCES medsim.doctors(id) ON DELETE CASCADE,
    weekday VARCHAR(20) CHECK (weekday IN ('monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday')) NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    UNIQUE (doctor_id, weekday, start_time)
);

-- Chat
CREATE TABLE medsim.chat (
    id SERIAL PRIMARY KEY,
    sender_id INT NOT NULL REFERENCES medsim.users(id) ON DELETE CASCADE,
    receiver_id INT NOT NULL REFERENCES medsim.users(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
