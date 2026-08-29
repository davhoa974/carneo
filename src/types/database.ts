export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.5"
  }
  graphql_public: {
    Tables: {
      [_ in never]: never
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      graphql: {
        Args: {
          extensions?: Json
          operationName?: string
          query?: string
          variables?: Json
        }
        Returns: Json
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  public: {
    Tables: {
      documents: {
        Row: {
          created_at: string
          file_name: string
          id: string
          mime_type: string
          ocr_data: Json | null
          ocr_status: Database["public"]["Enums"]["ocr_status"]
          size: number
          storage_path: string
          updated_at: string
          uploaded_at: string
          vehicle_id: string
        }
        Insert: {
          created_at?: string
          file_name: string
          id?: string
          mime_type: string
          ocr_data?: Json | null
          ocr_status?: Database["public"]["Enums"]["ocr_status"]
          size: number
          storage_path: string
          updated_at?: string
          uploaded_at?: string
          vehicle_id: string
        }
        Update: {
          created_at?: string
          file_name?: string
          id?: string
          mime_type?: string
          ocr_data?: Json | null
          ocr_status?: Database["public"]["Enums"]["ocr_status"]
          size?: number
          storage_path?: string
          updated_at?: string
          uploaded_at?: string
          vehicle_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "documents_vehicle_id_fkey"
            columns: ["vehicle_id"]
            isOneToOne: false
            referencedRelation: "vehicles"
            referencedColumns: ["id"]
          },
        ]
      }
      maintenance_events: {
        Row: {
          cost: number | null
          created_at: string
          document_id: string | null
          garage: string | null
          id: string
          label: string
          mileage: number | null
          notes: string | null
          performed_at: string
          plan_operation_id: string | null
          updated_at: string
          vehicle_id: string
        }
        Insert: {
          cost?: number | null
          created_at?: string
          document_id?: string | null
          garage?: string | null
          id?: string
          label: string
          mileage?: number | null
          notes?: string | null
          performed_at: string
          plan_operation_id?: string | null
          updated_at?: string
          vehicle_id: string
        }
        Update: {
          cost?: number | null
          created_at?: string
          document_id?: string | null
          garage?: string | null
          id?: string
          label?: string
          mileage?: number | null
          notes?: string | null
          performed_at?: string
          plan_operation_id?: string | null
          updated_at?: string
          vehicle_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "maintenance_events_document_id_fkey"
            columns: ["document_id"]
            isOneToOne: false
            referencedRelation: "documents"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "maintenance_events_plan_operation_id_fkey"
            columns: ["plan_operation_id"]
            isOneToOne: false
            referencedRelation: "plan_operations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "maintenance_events_vehicle_id_fkey"
            columns: ["vehicle_id"]
            isOneToOne: false
            referencedRelation: "vehicles"
            referencedColumns: ["id"]
          },
        ]
      }
      maintenance_plans: {
        Row: {
          created_at: string
          engine: string | null
          id: string
          make: string
          model: string
          name: string
          source: string
          updated_at: string
          user_id: string | null
          year_from: number | null
          year_to: number | null
        }
        Insert: {
          created_at?: string
          engine?: string | null
          id?: string
          make: string
          model: string
          name: string
          source: string
          updated_at?: string
          user_id?: string | null
          year_from?: number | null
          year_to?: number | null
        }
        Update: {
          created_at?: string
          engine?: string | null
          id?: string
          make?: string
          model?: string
          name?: string
          source?: string
          updated_at?: string
          user_id?: string | null
          year_from?: number | null
          year_to?: number | null
        }
        Relationships: []
      }
      mileage_readings: {
        Row: {
          created_at: string
          id: string
          mileage: number
          recorded_at: string
          updated_at: string
          vehicle_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          mileage: number
          recorded_at: string
          updated_at?: string
          vehicle_id: string
        }
        Update: {
          created_at?: string
          id?: string
          mileage?: number
          recorded_at?: string
          updated_at?: string
          vehicle_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "mileage_readings_vehicle_id_fkey"
            columns: ["vehicle_id"]
            isOneToOne: false
            referencedRelation: "vehicles"
            referencedColumns: ["id"]
          },
        ]
      }
      plan_operations: {
        Row: {
          category: Database["public"]["Enums"]["operation_category"]
          created_at: string
          criticality: Database["public"]["Enums"]["criticality"]
          first_due_months: number | null
          id: string
          interval_km: number | null
          interval_months: number | null
          maintenance_plan_id: string
          name: string
          notes: string | null
          updated_at: string
        }
        Insert: {
          category: Database["public"]["Enums"]["operation_category"]
          created_at?: string
          criticality: Database["public"]["Enums"]["criticality"]
          first_due_months?: number | null
          id?: string
          interval_km?: number | null
          interval_months?: number | null
          maintenance_plan_id: string
          name: string
          notes?: string | null
          updated_at?: string
        }
        Update: {
          category?: Database["public"]["Enums"]["operation_category"]
          created_at?: string
          criticality?: Database["public"]["Enums"]["criticality"]
          first_due_months?: number | null
          id?: string
          interval_km?: number | null
          interval_months?: number | null
          maintenance_plan_id?: string
          name?: string
          notes?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "plan_operations_maintenance_plan_id_fkey"
            columns: ["maintenance_plan_id"]
            isOneToOne: false
            referencedRelation: "maintenance_plans"
            referencedColumns: ["id"]
          },
        ]
      }
      vehicles: {
        Row: {
          created_at: string
          engine: string | null
          first_registration_date: string | null
          fuel_type: Database["public"]["Enums"]["fuel_type"]
          id: string
          maintenance_plan_id: string | null
          make: string
          model: string
          plate: string | null
          purchase_date: string | null
          purchase_mileage: number | null
          purchase_price: number | null
          updated_at: string
          user_id: string
          year: number
        }
        Insert: {
          created_at?: string
          engine?: string | null
          first_registration_date?: string | null
          fuel_type: Database["public"]["Enums"]["fuel_type"]
          id?: string
          maintenance_plan_id?: string | null
          make: string
          model: string
          plate?: string | null
          purchase_date?: string | null
          purchase_mileage?: number | null
          purchase_price?: number | null
          updated_at?: string
          user_id: string
          year: number
        }
        Update: {
          created_at?: string
          engine?: string | null
          first_registration_date?: string | null
          fuel_type?: Database["public"]["Enums"]["fuel_type"]
          id?: string
          maintenance_plan_id?: string | null
          make?: string
          model?: string
          plate?: string | null
          purchase_date?: string | null
          purchase_mileage?: number | null
          purchase_price?: number | null
          updated_at?: string
          user_id?: string
          year?: number
        }
        Relationships: [
          {
            foreignKeyName: "vehicles_maintenance_plan_id_fkey"
            columns: ["maintenance_plan_id"]
            isOneToOne: false
            referencedRelation: "maintenance_plans"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      [_ in never]: never
    }
    Enums: {
      criticality: "critique" | "recommande" | "confort"
      fuel_type: "essence" | "diesel" | "hybride" | "electrique" | "gpl"
      ocr_status: "en_attente" | "reussi" | "echec"
      operation_category:
        | "moteur"
        | "filtration"
        | "freinage"
        | "pneumatiques"
        | "reglementaire"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  graphql_public: {
    Enums: {},
  },
  public: {
    Enums: {
      criticality: ["critique", "recommande", "confort"],
      fuel_type: ["essence", "diesel", "hybride", "electrique", "gpl"],
      ocr_status: ["en_attente", "reussi", "echec"],
      operation_category: [
        "moteur",
        "filtration",
        "freinage",
        "pneumatiques",
        "reglementaire",
      ],
    },
  },
} as const
