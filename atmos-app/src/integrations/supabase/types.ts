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
    PostgrestVersion: "14.4"
  }
  public: {
    Tables: {
      arguments: {
        Row: {
          case_id: string
          content: string | null
          created_at: string | null
          description: string | null
          id: string
          label: string
          pos_x: number | null
          pos_y: number | null
          side: string
          strength: number | null
        }
        Insert: {
          case_id: string
          content?: string | null
          created_at?: string | null
          description?: string | null
          id?: string
          label: string
          pos_x?: number | null
          pos_y?: number | null
          side: string
          strength?: number | null
        }
        Update: {
          case_id?: string
          content?: string | null
          created_at?: string | null
          description?: string | null
          id?: string
          label?: string
          pos_x?: number | null
          pos_y?: number | null
          side?: string
          strength?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "arguments_case_id_fkey"
            columns: ["case_id"]
            isOneToOne: false
            referencedRelation: "cases"
            referencedColumns: ["id"]
          },
        ]
      }
      business_options: {
        Row: {
          created_at: string
          id: string
          option_data: Json
          scenario_id: string
          sort_order: number
          updated_at: string
        }
        Insert: {
          created_at?: string
          id?: string
          option_data?: Json
          scenario_id: string
          sort_order?: number
          updated_at?: string
        }
        Update: {
          created_at?: string
          id?: string
          option_data?: Json
          scenario_id?: string
          sort_order?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "business_options_scenario_id_fkey"
            columns: ["scenario_id"]
            isOneToOne: false
            referencedRelation: "business_scenarios"
            referencedColumns: ["id"]
          },
        ]
      }
      business_scenarios: {
        Row: {
          category: string
          company: string
          created_at: string
          description: string
          id: string
          notes: string
          outcome_date: string | null
          outcome_notes: string
          outcome_rating: number | null
          selected_option_id: string | null
          status: string
          title: string
          updated_at: string
          user_id: string
        }
        Insert: {
          category?: string
          company?: string
          created_at?: string
          description?: string
          id?: string
          notes?: string
          outcome_date?: string | null
          outcome_notes?: string
          outcome_rating?: number | null
          selected_option_id?: string | null
          status?: string
          title?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          category?: string
          company?: string
          created_at?: string
          description?: string
          id?: string
          notes?: string
          outcome_date?: string | null
          outcome_notes?: string
          outcome_rating?: number | null
          selected_option_id?: string | null
          status?: string
          title?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      cases: {
        Row: {
          court: string | null
          created_at: string | null
          fristen: Json | null
          goal: string | null
          id: string
          instanz: string | null
          kernfrage: string | null
          kosten: Json | null
          name: string
          number: string | null
          outcome_date: string | null
          outcome_notes: string
          outcome_rating: number | null
          status: string | null
          type: string | null
          updated_at: string | null
          user_id: string | null
        }
        Insert: {
          court?: string | null
          created_at?: string | null
          fristen?: Json | null
          goal?: string | null
          id?: string
          instanz?: string | null
          kernfrage?: string | null
          kosten?: Json | null
          name: string
          number?: string | null
          outcome_date?: string | null
          outcome_notes?: string
          outcome_rating?: number | null
          status?: string | null
          type?: string | null
          updated_at?: string | null
          user_id?: string | null
        }
        Update: {
          court?: string | null
          created_at?: string | null
          fristen?: Json | null
          goal?: string | null
          id?: string
          instanz?: string | null
          kernfrage?: string | null
          kosten?: Json | null
          name?: string
          number?: string | null
          outcome_date?: string | null
          outcome_notes?: string
          outcome_rating?: number | null
          status?: string | null
          type?: string | null
          updated_at?: string | null
          user_id?: string | null
        }
        Relationships: []
      }
      edges: {
        Row: {
          case_id: string
          from_arg_id: string
          id: string
          to_arg_id: string
          type: string
        }
        Insert: {
          case_id: string
          from_arg_id: string
          id?: string
          to_arg_id: string
          type: string
        }
        Update: {
          case_id?: string
          from_arg_id?: string
          id?: string
          to_arg_id?: string
          type?: string
        }
        Relationships: [
          {
            foreignKeyName: "edges_case_id_fkey"
            columns: ["case_id"]
            isOneToOne: false
            referencedRelation: "cases"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "edges_from_arg_id_fkey"
            columns: ["from_arg_id"]
            isOneToOne: false
            referencedRelation: "arguments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "edges_to_arg_id_fkey"
            columns: ["to_arg_id"]
            isOneToOne: false
            referencedRelation: "arguments"
            referencedColumns: ["id"]
          },
        ]
      }
      evidence: {
        Row: {
          argument_id: string
          case_id: string
          description: string | null
          id: string
          name: string
          strength: number | null
          type: string | null
          validity: number | null
        }
        Insert: {
          argument_id: string
          case_id: string
          description?: string | null
          id?: string
          name: string
          strength?: number | null
          type?: string | null
          validity?: number | null
        }
        Update: {
          argument_id?: string
          case_id?: string
          description?: string | null
          id?: string
          name?: string
          strength?: number | null
          type?: string | null
          validity?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "evidence_argument_id_fkey"
            columns: ["argument_id"]
            isOneToOne: false
            referencedRelation: "arguments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "evidence_case_id_fkey"
            columns: ["case_id"]
            isOneToOne: false
            referencedRelation: "cases"
            referencedColumns: ["id"]
          },
        ]
      }
      persons: {
        Row: {
          affective_empathy: number | null
          avg_duration: string | null
          case_id: string
          cognitive_empathy: number | null
          coldness: number | null
          competence_level: number | null
          conflict_of_interest: number | null
          court: string | null
          fear_factor: number | null
          hidden_motive: number | null
          historical_cases: number | null
          historical_consistency: number | null
          id: string
          legal_levers: Json | null
          loyalty_signals: number | null
          manipulation_skill: number | null
          name: string
          narcissism: number | null
          party: string | null
          past_case_notes: string | null
          plaintiff_win_rate: number | null
          prior_contradictions: number | null
          psych_levers: Json | null
          question_modules: Json | null
          role: string
          self_preservation: number | null
          settle_rate: number | null
        }
        Insert: {
          affective_empathy?: number | null
          avg_duration?: string | null
          case_id: string
          cognitive_empathy?: number | null
          coldness?: number | null
          competence_level?: number | null
          conflict_of_interest?: number | null
          court?: string | null
          fear_factor?: number | null
          hidden_motive?: number | null
          historical_cases?: number | null
          historical_consistency?: number | null
          id?: string
          legal_levers?: Json | null
          loyalty_signals?: number | null
          manipulation_skill?: number | null
          name: string
          narcissism?: number | null
          party?: string | null
          past_case_notes?: string | null
          plaintiff_win_rate?: number | null
          prior_contradictions?: number | null
          psych_levers?: Json | null
          question_modules?: Json | null
          role: string
          self_preservation?: number | null
          settle_rate?: number | null
        }
        Update: {
          affective_empathy?: number | null
          avg_duration?: string | null
          case_id?: string
          cognitive_empathy?: number | null
          coldness?: number | null
          competence_level?: number | null
          conflict_of_interest?: number | null
          court?: string | null
          fear_factor?: number | null
          hidden_motive?: number | null
          historical_cases?: number | null
          historical_consistency?: number | null
          id?: string
          legal_levers?: Json | null
          loyalty_signals?: number | null
          manipulation_skill?: number | null
          name?: string
          narcissism?: number | null
          party?: string | null
          past_case_notes?: string | null
          plaintiff_win_rate?: number | null
          prior_contradictions?: number | null
          psych_levers?: Json | null
          question_modules?: Json | null
          role?: string
          self_preservation?: number | null
          settle_rate?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "persons_case_id_fkey"
            columns: ["case_id"]
            isOneToOne: false
            referencedRelation: "cases"
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
      [_ in never]: never
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
  public: {
    Enums: {},
  },
} as const
