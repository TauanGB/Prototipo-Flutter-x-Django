#!/usr/bin/env python3
"""
Script para adicionar motoristas de teste ao banco de dados
"""
import os
import sys
import django
from datetime import datetime, timedelta
import random

# Configurar Django
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from apps.core.models import Driver, DriverLocation, DriverTrip
from django.utils import timezone


def create_test_drivers():
    """Cria motoristas de teste com CPFs fictícios"""
    print("🚗 CRIANDO MOTORISTAS DE TESTE")
    print("=" * 50)
    
    # Lista de motoristas de teste
    test_drivers = [
        {
            'cpf': '12345678901',
            'name': 'João Silva Santos',
            'phone': '(11) 99999-1111'
        },
        {
            'cpf': '98765432100',
            'name': 'Maria Oliveira Costa',
            'phone': '(11) 99999-2222'
        },
        {
            'cpf': '11122233344',
            'name': 'Pedro Almeida Lima',
            'phone': '(11) 99999-3333'
        },
        {
            'cpf': '55566677788',
            'name': 'Ana Paula Rodrigues',
            'phone': '(11) 99999-4444'
        },
        {
            'cpf': '99988877766',
            'name': 'Carlos Eduardo Souza',
            'phone': '(11) 99999-5555'
        }
    ]
    
    created_drivers = []
    
    for driver_data in test_drivers:
        try:
            # Verifica se o motorista já existe
            driver, created = Driver.objects.get_or_create(
                cpf=driver_data['cpf'],
                defaults={
                    'name': driver_data['name'],
                    'phone': driver_data['phone'],
                    'is_active': True
                }
            )
            
            if created:
                print(f"✅ Motorista criado: {driver.name} - {driver.cpf}")
                created_drivers.append(driver)
            else:
                print(f"⚠️  Motorista já existe: {driver.name} - {driver.cpf}")
                
        except Exception as e:
            print(f"❌ Erro ao criar motorista {driver_data['name']}: {e}")
    
    return created_drivers


def create_test_locations(drivers):
    """Cria localizações de teste para os motoristas"""
    print("\n📍 CRIANDO LOCALIZAÇÕES DE TESTE")
    print("=" * 50)
    
    # Coordenadas de São Paulo para teste
    sp_coordinates = [
        {'lat': -23.5505, 'lng': -46.6333, 'name': 'Centro SP'},
        {'lat': -23.5615, 'lng': -46.6565, 'name': 'Vila Madalena'},
        {'lat': -23.5489, 'lng': -46.6388, 'name': 'Bela Vista'},
        {'lat': -23.5329, 'lng': -46.6399, 'name': 'Vila Olímpia'},
        {'lat': -23.5671, 'lng': -46.6525, 'name': 'Pinheiros'}
    ]
    
    for driver in drivers:
        # Cria 3-5 localizações para cada motorista
        num_locations = random.randint(3, 5)
        
        for i in range(num_locations):
            coord = random.choice(sp_coordinates)
            
            # Adiciona variação aleatória nas coordenadas
            lat_variation = random.uniform(-0.01, 0.01)
            lng_variation = random.uniform(-0.01, 0.01)
            
            location = DriverLocation.objects.create(
                driver=driver,
                latitude=coord['lat'] + lat_variation,
                longitude=coord['lng'] + lng_variation,
                accuracy=random.uniform(5.0, 20.0),
                speed=random.uniform(0, 60),
                battery_level=random.randint(20, 100),
                timestamp=timezone.now() - timedelta(hours=random.randint(1, 24))
            )
            
        print(f"✅ {num_locations} localizações criadas para {driver.name}")


def create_test_trips(drivers):
    """Cria viagens de teste para os motoristas"""
    print("\n🚗 CRIANDO VIAGENS DE TESTE")
    print("=" * 50)
    
    for driver in drivers:
        # Cria 1-3 viagens para cada motorista
        num_trips = random.randint(1, 3)
        
        for i in range(num_trips):
            # Coordenadas de início e fim aleatórias
            start_lat = -23.5505 + random.uniform(-0.05, 0.05)
            start_lng = -46.6333 + random.uniform(-0.05, 0.05)
            end_lat = -23.5505 + random.uniform(-0.05, 0.05)
            end_lng = -46.6333 + random.uniform(-0.05, 0.05)
            
            # Status aleatório (mais completed que started)
            status = random.choices(['started', 'completed'], weights=[1, 3])[0]
            
            trip = DriverTrip.objects.create(
                driver=driver,
                start_latitude=start_lat,
                start_longitude=start_lng,
                end_latitude=end_lat if status == 'completed' else None,
                end_longitude=end_lng if status == 'completed' else None,
                status=status,
                distance_km=random.uniform(2.0, 15.0) if status == 'completed' else None,
                duration_minutes=random.randint(10, 120) if status == 'completed' else None,
                started_at=timezone.now() - timedelta(hours=random.randint(1, 48)),
                completed_at=timezone.now() - timedelta(hours=random.randint(1, 24)) if status == 'completed' else None
            )
            
        print(f"✅ {num_trips} viagens criadas para {driver.name}")


def show_summary():
    """Mostra resumo dos dados criados"""
    print("\n📊 RESUMO DOS DADOS")
    print("=" * 50)
    
    total_drivers = Driver.objects.count()
    total_locations = DriverLocation.objects.count()
    total_trips = DriverTrip.objects.count()
    
    print(f"👥 Total de Motoristas: {total_drivers}")
    print(f"📍 Total de Localizações: {total_locations}")
    print(f"🚗 Total de Viagens: {total_trips}")
    
    print("\n📋 Lista de Motoristas:")
    for driver in Driver.objects.all():
        locations_count = driver.locations.count()
        trips_count = driver.trips.count()
        print(f"  • {driver.name} ({driver.cpf}) - {locations_count} locs, {trips_count} trips")


def main():
    """Função principal"""
    print("🚀 SCRIPT DE CRIAÇÃO DE DADOS DE TESTE")
    print("=" * 50)
    
    try:
        # Criar motoristas
        drivers = create_test_drivers()
        
        if not drivers:
            print("⚠️  Nenhum motorista novo foi criado. Verificando motoristas existentes...")
            drivers = list(Driver.objects.all())
        
        if drivers:
            # Criar localizações
            create_test_locations(drivers)
            
            # Criar viagens
            create_test_trips(drivers)
            
            # Mostrar resumo
            show_summary()
            
            print("\n🎉 Dados de teste criados com sucesso!")
            print("\n💡 Agora você pode testar a API com os CPFs:")
            for driver in Driver.objects.all():
                print(f"   • {driver.cpf} - {driver.name}")
                
        else:
            print("❌ Nenhum motorista disponível para criar dados de teste")
            
    except Exception as e:
        print(f"❌ Erro durante a execução: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()
